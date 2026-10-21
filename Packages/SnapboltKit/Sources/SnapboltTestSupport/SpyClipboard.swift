// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation

// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.
import Foundation
import SnapboltCore

/// Records what was written to the clipboard.
@MainActor
public final class SpyClipboard: ClipboardWriting {
    public private(set) var writtenURLs: [URL] = []
    public private(set) var writtenImages: [EncodedImage] = []

    public init() {}

    public func writeURL(_ url: URL) {
        writtenURLs.append(url)
    }

    public func writeImage(_ image: EncodedImage) {
        writtenImages.append(image)
    }
}
