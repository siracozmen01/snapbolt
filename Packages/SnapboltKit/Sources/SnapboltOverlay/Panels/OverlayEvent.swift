import CoreGraphics

/// Input from an overlay panel, with locations in AppKit global points.
enum OverlayEvent {
    case moved(CGPoint)
    case pressed(CGPoint)
    case dragged(CGPoint)
    case released(CGPoint)
    /// Return: capture the whole display under the point.
    case selectDisplay(CGPoint)
    /// Escape.
    case cancel
}

/// What every overlay panel draws, in AppKit global points.
struct OverlayState {
    var region: CGRect?
    var highlight: CGRect?
    var cursor: CGPoint?
}
