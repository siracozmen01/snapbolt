import CoreGraphics

/// A zoom request from a shortcut or the toolbar.
enum ZoomCommand: Sendable {
    case zoomIn
    case zoomOut
    case fit
    case actualSize
    /// A specific magnification from the zoom menu; 1 is 100%.
    case magnification(CGFloat)
}
