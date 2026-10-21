import Foundation

/// The outcome of a successful upload.
public struct UploadResult: Equatable, Sendable {
    /// The object key inside the bucket.
    public let objectKey: String
    /// The URL anyone can open to see the upload.
    public let publicURL: URL

    /// Creates an upload result.
    public init(objectKey: String, publicURL: URL) {
        self.objectKey = objectKey
        self.publicURL = publicURL
    }
}
