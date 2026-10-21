import Foundation

/// Puts capture results on the clipboard.
@MainActor
public protocol ClipboardWriting {
    /// Replaces the clipboard contents with `url`.
    func writeURL(_ url: URL)
    /// Replaces the clipboard contents with `image`.
    func writeImage(_ image: EncodedImage)
}
