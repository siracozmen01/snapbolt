/// Remembers recent uploads.
public protocol UploadHistoryStoring: Sendable {
    /// Records an upload.
    func add(_ entry: HistoryEntry) async throws
    /// Returns the most recent uploads, newest first.
    func recentEntries() async -> [HistoryEntry]
}
