import CoreGraphics
import SnapboltCore

/// A straight arrow with a filled triangular head at its end.
struct ArrowAnnotation: AnnotationShape {
    var startInPixels: CGPoint
    var endInPixels: CGPoint
    var color: RGBAColor
    var lineWidthInPixels: CGFloat

    /// The head's length (and width): four line widths, at least 10 px.
    var headLengthInPixels: CGFloat { max(lineWidthInPixels * 4, 10) }

    /// Where the shaft stops: at the head's base, so translucent colours do not overlap.
    var shaftEndInPixels: CGPoint {
        let length = self.length
        guard length > headLengthInPixels else { return startInPixels }
        let ratio = (length - headLengthInPixels) / length
        return CGPoint(
            x: startInPixels.x + (endInPixels.x - startInPixels.x) * ratio,
            y: startInPixels.y + (endInPixels.y - startInPixels.y) * ratio)
    }

    /// The head's corners: tip, then the two base corners.
    var headPointsInPixels: [CGPoint] {
        let unit = direction
        let base = CGPoint(
            x: endInPixels.x - unit.dx * headLengthInPixels, y: endInPixels.y - unit.dy * headLengthInPixels)
        let half = headLengthInPixels / 2
        return [
            endInPixels,
            CGPoint(x: base.x - unit.dy * half, y: base.y + unit.dx * half),
            CGPoint(x: base.x + unit.dy * half, y: base.y - unit.dx * half),
        ]
    }

    var boundsInPixels: CGRect {
        let points = [startInPixels] + headPointsInPixels
        let minX = points.map(\.x).min() ?? 0
        let minY = points.map(\.y).min() ?? 0
        let maxX = points.map(\.x).max() ?? 0
        let maxY = points.map(\.y).max() ?? 0
        let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return rect.insetBy(dx: -lineWidthInPixels / 2, dy: -lineWidthInPixels / 2)
    }

    var handlePositions: [Handle: CGPoint] { [.start: startInPixels, .end: endInPixels] }

    private var length: CGFloat { hypot(endInPixels.x - startInPixels.x, endInPixels.y - startInPixels.y) }

    /// The unit vector from start to end.
    private var direction: CGVector {
        let length = max(self.length, 0.001)
        return CGVector(dx: (endInPixels.x - startInPixels.x) / length, dy: (endInPixels.y - startInPixels.y) / length)
    }

    func contains(_ pointInPixels: CGPoint, toleranceInPixels: CGFloat) -> Bool {
        distance(from: pointInPixels) <= toleranceInPixels + lineWidthInPixels / 2
    }

    func moved(by offset: CGVector) -> ArrowAnnotation {
        var arrow = self
        arrow.startInPixels = CGPoint(x: startInPixels.x + offset.dx, y: startInPixels.y + offset.dy)
        arrow.endInPixels = CGPoint(x: endInPixels.x + offset.dx, y: endInPixels.y + offset.dy)
        return arrow
    }

    func resized(dragging handle: Handle, to pointInPixels: CGPoint) -> ArrowAnnotation {
        var arrow = self
        switch handle {
        case .start: arrow.startInPixels = pointInPixels
        case .end: arrow.endInPixels = pointInPixels
        default: break
        }
        return arrow
    }

    func restyled(_ style: ToolStyle, scale: CGFloat) -> ArrowAnnotation {
        var arrow = self
        arrow.color = style.color
        arrow.lineWidthInPixels = CanvasMapping(scale: scale).pixels(fromPoints: style.lineWidthInPoints)
        return arrow
    }

    func style(applyingTo base: ToolStyle, scale: CGFloat) -> ToolStyle {
        var style = base
        style.color = color
        style.lineWidthInPoints = CanvasMapping(scale: scale).points(fromPixels: lineWidthInPixels)
        return style
    }

    /// The distance from `point` to the segment between start and end.
    private func distance(from point: CGPoint) -> CGFloat {
        let segment = CGVector(dx: endInPixels.x - startInPixels.x, dy: endInPixels.y - startInPixels.y)
        let lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy
        guard lengthSquared > 0 else { return hypot(point.x - startInPixels.x, point.y - startInPixels.y) }
        let projection =
            ((point.x - startInPixels.x) * segment.dx + (point.y - startInPixels.y) * segment.dy) / lengthSquared
        let fraction = min(max(projection, 0), 1)
        return hypot(
            point.x - (startInPixels.x + fraction * segment.dx), point.y - (startInPixels.y + fraction * segment.dy))
    }
}
