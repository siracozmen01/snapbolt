import CoreGraphics

/// Cuts the selected part out of a frozen display image.
public enum ImageCropper {
    /// Returns the pixels of `screens` covered by `selection`.
    /// - Throws: ``CaptureError/displayNotFound`` or ``CaptureError/emptySelection``.
    public static func crop(_ screens: FrozenScreens, to selection: Selection) throws(CaptureError) -> CGImage {
        let rect = rectInPixels(of: selection)
        guard let display = screens.display(withID: selection.displayID) else { throw .displayNotFound }
        guard let rect else { return display.image }
        let bounds = CGRect(x: 0, y: 0, width: display.image.width, height: display.image.height)
        let clipped = rect.intersection(bounds)
        guard !clipped.isEmpty, let image = display.image.cropping(to: clipped) else { throw .emptySelection }
        return image
    }

    private static func rectInPixels(of selection: Selection) -> CGRect? {
        switch selection {
        case .region(_, let rect), .window(_, let rect):
            rect
        case .display:
            nil
        }
    }
}
