// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation
// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.
import CoreGraphics
import Foundation
import SnapboltCore
import Synchronization

/// Records the pixel size of every encoded image and returns placeholder PNG bytes.
public final class FakeImageEncoder: ImageEncoding {
    private let state = Mutex<[CGSize]>([])
    private let failure: CaptureError?

    public init(failure: CaptureError? = nil) {
        self.failure = failure
    }

    public var encodedSizes: [CGSize] { state.withLock { $0 } }

    public func encodePNG(_ image: CGImage) throws -> EncodedImage {
        if let failure { throw failure }
        state.withLock { $0.append(CGSize(width: image.width, height: image.height)) }
        return EncodedImage(data: Data("png".utf8), contentType: "image/png", fileExtension: "png")
    }
}
