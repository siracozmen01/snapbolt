// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation

// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.
import SnapboltCore

/// In-memory upload history, newest first.
public actor FakeHistoryStore: UploadHistoryStoring {
    public private(set) var entries: [HistoryEntry] = []

    public init() {}

    public func add(_ entry: HistoryEntry) async throws {
        entries.insert(entry, at: 0)
    }

    public func recentEntries() async -> [HistoryEntry] {
        entries
    }
}
