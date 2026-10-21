/// Checks that storage settings work end to end.
public protocol ConnectionTesting: Sendable {
    /// Uploads, reads back through the public URL and deletes a small test object.
    func testConnection(using settings: StorageSettings) async -> ConnectionTestOutcome
}
