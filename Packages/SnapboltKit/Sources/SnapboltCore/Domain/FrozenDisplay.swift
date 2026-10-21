import CoreGraphics

/// One display captured at the moment a capture shortcut was pressed.
public struct FrozenDisplay: Sendable {
    /// The display this image was captured from.
    public let id: DisplayID
    /// The full-resolution image of the display, in display pixels.
    public let image: CGImage
    /// The display's frame in AppKit global points (origin bottom-left of the primary display, y up).
    public let frameInGlobalPoints: CGRect
    /// Pixels per point.
    public let scale: CGFloat

    /// Creates a frozen display.
    public init(id: DisplayID, image: CGImage, frameInGlobalPoints: CGRect, scale: CGFloat) {
        self.id = id
        self.image = image
        self.frameInGlobalPoints = frameInGlobalPoints
        self.scale = scale
    }
}
