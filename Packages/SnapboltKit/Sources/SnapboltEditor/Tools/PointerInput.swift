import CoreGraphics

/// One mouse event as the tools see it: a position in image pixels plus what affects its meaning.
struct PointerInput: Sendable {
    var pointInPixels: CGPoint
    var isShiftDown: Bool
    var clickCount: Int
    /// How far from a shape or handle a press still grabs it.
    var toleranceInPixels: CGFloat
    /// Pixels per point of the capture, for converting styles and minimum sizes.
    var scale: CGFloat

    init(
        pointInPixels: CGPoint, isShiftDown: Bool = false, clickCount: Int = 1, toleranceInPixels: CGFloat = 6,
        scale: CGFloat = 1
    ) {
        self.pointInPixels = pointInPixels
        self.isShiftDown = isShiftDown
        self.clickCount = clickCount
        self.toleranceInPixels = toleranceInPixels
        self.scale = scale
    }
}
