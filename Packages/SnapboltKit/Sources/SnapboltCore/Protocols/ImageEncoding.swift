import CoreGraphics

/// Turns images into bytes.
public protocol ImageEncoding: Sendable {
    /// Encodes `image` as PNG.
    /// - Throws: ``CaptureError/encodingFailed``.
    func encodePNG(_ image: CGImage) throws -> EncodedImage
}
