import CoreGraphics

/// The geometry and style every kind of annotation provides. All positions are image pixels.
protocol AnnotationShape: Equatable, Sendable {
    /// The area the shape covers when drawn, including its line width.
    var boundsInPixels: CGRect { get }
    /// The handles the user can drag and where they are.
    var handlePositions: [Handle: CGPoint] { get }
    /// Whether a press at `pointInPixels` grabs this shape.
    func contains(_ pointInPixels: CGPoint, toleranceInPixels: CGFloat) -> Bool
    /// The shape moved by `offset` pixels.
    func moved(by offset: CGVector) -> Self
    /// The shape with `handle` dragged to `pointInPixels`.
    func resized(dragging handle: Handle, to pointInPixels: CGPoint) -> Self
    /// The shape drawn with `style`, whose sizes are in points of a capture with `scale` pixels per point.
    func restyled(_ style: ToolStyle, scale: CGFloat) -> Self
    /// `base` with the properties this shape controls replaced by the shape's own values.
    func style(applyingTo base: ToolStyle, scale: CGFloat) -> ToolStyle
}
