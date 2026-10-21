import AppKit
import SnapboltCore

/// Writes capture results to the system clipboard.
@MainActor
public final class PasteboardClipboard: ClipboardWriting {
    private let pasteboard: NSPasteboard

    /// Creates a clipboard writer for `pasteboard`.
    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    /// Replaces the clipboard with `url`, as both text and a URL.
    public func writeURL(_ url: URL) {
        pasteboard.clearContents()
        pasteboard.setString(url.absoluteString, forType: .string)
        pasteboard.setString(url.absoluteString, forType: .URL)
    }

    /// Replaces the clipboard with `image`.
    public func writeImage(_ image: EncodedImage) {
        pasteboard.clearContents()
        pasteboard.setData(image.data, forType: .png)
    }
}
