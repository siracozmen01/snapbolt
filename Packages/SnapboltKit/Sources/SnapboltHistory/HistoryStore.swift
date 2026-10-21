import Foundation
import SnapboltCore

/// The most recent uploads, persisted as JSON.
public actor HistoryStore: UploadHistoryStoring {
    /// `~/Library/Application Support/Snapbolt/history.json`.
    public static let defaultFileURL = URL.applicationSupportDirectory
        .appending(path: "Snapbolt", directoryHint: .isDirectory)
        .appending(path: "history.json")

    private let fileURL: URL
    private let limit: Int
    private var entries: [HistoryEntry]?

    /// Creates a store that keeps the newest `limit` uploads in `fileURL`.
    public init(fileURL: URL, limit: Int = 10) {
        self.fileURL = fileURL
        self.limit = limit
    }

    /// Records an upload and writes the history to disk.
    public func add(_ entry: HistoryEntry) async throws {
        let updated = Array(([entry] + loadedEntries()).prefix(limit))
        entries = updated
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Self.encoder.encode(updated).write(to: fileURL, options: .atomic)
    }

    /// Returns the recent uploads, newest first.
    public func recentEntries() async -> [HistoryEntry] {
        loadedEntries()
    }

    private func loadedEntries() -> [HistoryEntry] {
        if let entries { return entries }
        let loaded = readFile()
        entries = loaded
        return loaded
    }

    private func readFile() -> [HistoryEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return [] }
        do {
            return try Self.decoder.decode([HistoryEntry].self, from: Data(contentsOf: fileURL))
        } catch {
            // A damaged history must not break capturing; it is replaced on the next upload.
            logger.error("Ignoring unreadable history: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
