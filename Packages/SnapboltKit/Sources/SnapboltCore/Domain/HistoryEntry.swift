import Foundation

/// One past upload, shown in the Recent Uploads menu.
public struct HistoryEntry: Codable, Equatable, Sendable {
    /// The public link of the upload.
    public let publicURL: URL
    /// When the upload finished.
    public let uploadedAt: Date

    /// Creates a history entry.
    public init(publicURL: URL, uploadedAt: Date) {
        self.publicURL = publicURL
        self.uploadedAt = uploadedAt
    }
}
