/// A zoom request from a shortcut or the toolbar.
enum ZoomCommand: Sendable {
    case zoomIn
    case zoomOut
    case fit
    case actualSize
}
