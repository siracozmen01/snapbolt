import CoreGraphics

/// Everything captured when a shortcut is pressed: one image per display and the visible windows.
public struct FrozenScreens: Sendable {
    /// The captured displays.
    public let displays: [FrozenDisplay]
    /// The on-screen windows, ordered front to back.
    public let windows: [WindowInfo]

    /// Creates frozen screens.
    public init(displays: [FrozenDisplay], windows: [WindowInfo]) {
        self.displays = displays
        self.windows = windows
    }

    /// Returns the display whose frame contains `pointInGlobalPoints`, if any.
    public func display(containing pointInGlobalPoints: CGPoint) -> FrozenDisplay? {
        displays.first { $0.frameInGlobalPoints.contains(pointInGlobalPoints) }
    }

    /// Returns the display with the given identifier, if it was captured.
    public func display(withID id: DisplayID) -> FrozenDisplay? {
        displays.first { $0.id == id }
    }
}
