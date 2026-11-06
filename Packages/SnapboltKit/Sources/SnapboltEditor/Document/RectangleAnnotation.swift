import CoreGraphics
import SnapboltCore

/// A rectangle, outlined or filled.
struct RectangleAnnotation: AnnotationShape {
    var rectInPixels: CGRect
    var color: RGBAColor
    var lineWidthInPixels: CGFloat
    var isFilled: Bool

    var boundsInPixels: CGRect { rectInPixels.insetBy(dx: -lineWidthInPixels / 2, dy: -lineWidthInPixels / 2) }

    var handlePositions: [Handle: CGPoint] { Handle.positions(for: rectInPixels) }

    func contains(_ pointInPixels: CGPoint, toleranceInPixels: CGFloat) -> Bool {
        if isFilled {
            return rectInPixels.insetBy(dx: -toleranceInPixels, dy: -toleranceInPixels).contains(pointInPixels)
        }
        let reach = toleranceInPixels + lineWidthInPixels / 2
        let inner = rectInPixels.insetBy(dx: reach, dy: reach)
        let isInsideInner = !inner.isNull && inner.contains(pointInPixels)
        return rectInPixels.insetBy(dx: -reach, dy: -reach).contains(pointInPixels) && !isInsideInner
    }

    func moved(by offset: CGVector) -> RectangleAnnotation {
        var rectangle = self
        rectangle.rectInPixels = rectInPixels.offsetBy(dx: offset.dx, dy: offset.dy)
        return rectangle
    }

    func resized(dragging handle: Handle, to pointInPixels: CGPoint) -> RectangleAnnotation {
        var rectangle = self
        rectangle.rectInPixels = RectResizing.resized(rectInPixels, dragging: handle, to: pointInPixels)
        return rectangle
    }

    func restyled(_ style: ToolStyle, scale: CGFloat) -> RectangleAnnotation {
        var rectangle = self
        rectangle.color = style.color
        rectangle.lineWidthInPixels = CanvasMapping(scale: scale).pixels(fromPoints: style.lineWidthInPoints)
        rectangle.isFilled = style.isFilled
        return rectangle
    }

    func style(applyingTo base: ToolStyle, scale: CGFloat) -> ToolStyle {
        var style = base
        style.color = color
        style.lineWidthInPoints = CanvasMapping(scale: scale).points(fromPixels: lineWidthInPixels)
        style.isFilled = isFilled
        return style
    }
}
