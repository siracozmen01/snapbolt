import CoreGraphics
import Foundation
import ImageIO
import SnapboltCore
import UniformTypeIdentifiers

/// Encodes captures as PNG with ImageIO.
public struct PNGEncoder: ImageEncoding {
    /// Creates an encoder.
    public init() {}

    /// Encodes `image` as PNG.
    /// - Throws: ``CaptureError/encodingFailed``.
    public func encodePNG(_ image: CGImage) throws -> EncodedImage {
        let data = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)
        else { throw CaptureError.encodingFailed }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw CaptureError.encodingFailed }
        return EncodedImage(data: data as Data, contentType: "image/png", fileExtension: "png")
    }
}
