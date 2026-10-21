import CoreGraphics

/// An on-screen window at the moment of capture, used for window selection.
public struct WindowInfo: Equatable, Sendable {
    /// The window server's window number.
    public let id: UInt32
    /// The name of the app that owns the window, when available.
    public let ownerName: String?
    /// The window title, when available.
    public let title: String?
    /// The window frame in AppKit global points (origin bottom-left of the primary display, y up).
    public let frameInGlobalPoints: CGRect

    /// Creates window metadata.
    public init(id: UInt32, ownerName: String?, title: String?, frameInGlobalPoints: CGRect) {
        self.id = id
        self.ownerName = ownerName
        self.title = title
        self.frameInGlobalPoints = frameInGlobalPoints
    }
}
