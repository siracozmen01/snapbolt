import CoreGraphics

/// Cuts the selected part out of a frozen display image.
public enum ImageCropper {
    /// Returns the pixels of `screens` covered by `selection`.
    /// - Throws: ``CaptureError/displayNotFound`` or ``CaptureError/emptySelection``.
    public static func crop(_ screens: FrozenScreens, to selection: Selection) throws(CaptureError) -> CGImage {
        let (displayID, rect) = target(of: selection)
        guard let display = screens.display(withID: displayID) else { throw .displayNotFound }
        guard let rect else { return display.image }
        let bounds = CGRect(x: 0, y: 0, width: display.image.width, height: display.image.height)
        let clipped = rect.intersection(bounds)
        guard !clipped.isEmpty, let image = display.image.cropping(to: clipped) else { throw .emptySelection }
        return image
    }

    private static func target(of selection: Selection) -> (DisplayID, CGRect?) {
        switch selection {
        case .region(let id, let rect), .window(let id, let rect):
            (id, rect)
        case .display(let id):
            (id, nil)
        }
    }
}
