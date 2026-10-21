import Foundation

/// Image bytes ready to save or upload.
public struct EncodedImage: Equatable, Sendable {
    /// The encoded bytes.
    public let data: Data
    /// The MIME type, e.g. `image/png`.
    public let contentType: String
    /// The file extension without a dot, e.g. `png`.
    public let fileExtension: String

    /// Creates an encoded image.
    public init(data: Data, contentType: String, fileExtension: String) {
        self.data = data
        self.contentType = contentType
        self.fileExtension = fileExtension
    }
}
