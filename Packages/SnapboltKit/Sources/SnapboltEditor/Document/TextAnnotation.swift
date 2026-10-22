import CoreGraphics
import SnapboltCore

/// One or more lines of text, optionally on a contrasting rounded box.
struct TextAnnotation: AnnotationShape {
    /// Text never shrinks below this size when resized by a handle.
    static let minimumFontSizeInPixels: CGFloat = 4
    private static let cornerHandles: [Handle] = [.topLeft, .topRight, .bottomRight, .bottomLeft]

    var string: String
    /// The top-left corner of the text's bounds, background included.
    var originInPixels: CGPoint
    var color: RGBAColor
    var fontSizeInPixels: CGFloat
    var hasBackground: Bool

    /// Space between the background box's edge and the text.
    var paddingInPixels: CGFloat { hasBackground ? fontSizeInPixels * 0.25 : 0 }

    var layout: TextLayout { TextLayout(string: string, fontSizeInPixels: fontSizeInPixels) }

    var boundsInPixels: CGRect {
        let size = layout.sizeInPixels
        return CGRect(
            x: originInPixels.x, y: originInPixels.y, width: size.width + 2 * paddingInPixels,
            height: size.height + 2 * paddingInPixels)
    }

    var handlePositions: [Handle: CGPoint] {
        Handle.positions(for: boundsInPixels).filter { Self.cornerHandles.contains($0.key) }
    }

    func contains(_ pointInPixels: CGPoint, toleranceInPixels: CGFloat) -> Bool {
        boundsInPixels.insetBy(dx: -toleranceInPixels, dy: -toleranceInPixels).contains(pointInPixels)
    }

    func moved(by offset: CGVector) -> TextAnnotation {
        var text = self
        text.originInPixels = CGPoint(x: originInPixels.x + offset.dx, y: originInPixels.y + offset.dy)
        return text
    }

    /// Scales the font by the change in height, keeping the corner opposite `handle` in place.
    func resized(dragging handle: Handle, to pointInPixels: CGPoint) -> TextAnnotation {
        let bounds = boundsInPixels
        guard Self.cornerHandles.contains(handle), bounds.height > 0 else { return self }
        let fixed = Self.opposite(of: handle, in: bounds)
        let factor = abs(pointInPixels.y - fixed.y) / bounds.height
        var text = self
        text.fontSizeInPixels = max(fontSizeInPixels * factor, Self.minimumFontSizeInPixels)
        let size = text.boundsInPixels.size
        let x = [.topLeft, .bottomLeft].contains(handle) ? fixed.x - size.width : fixed.x
        let y = [.topLeft, .topRight].contains(handle) ? fixed.y - size.height : fixed.y
        text.originInPixels = CGPoint(x: x, y: y)
        return text
    }

    func restyled(_ style: ToolStyle, scale: CGFloat) -> TextAnnotation {
        var text = self
        text.color = style.color
        text.fontSizeInPixels = CanvasMapping(scale: scale).pixels(fromPoints: style.fontSizeInPoints)
        text.hasBackground = style.hasBackground
        return text
    }

    func style(applyingTo base: ToolStyle, scale: CGFloat) -> ToolStyle {
        var style = base
        style.color = color
        style.fontSizeInPoints = CanvasMapping(scale: scale).points(fromPixels: fontSizeInPixels)
        style.hasBackground = hasBackground
        return style
    }

    private static func opposite(of handle: Handle, in bounds: CGRect) -> CGPoint {
        switch handle {
        case .topLeft: CGPoint(x: bounds.maxX, y: bounds.maxY)
        case .topRight: CGPoint(x: bounds.minX, y: bounds.maxY)
        case .bottomLeft: CGPoint(x: bounds.maxX, y: bounds.minY)
        default: CGPoint(x: bounds.minX, y: bounds.minY)
        }
    }
}
