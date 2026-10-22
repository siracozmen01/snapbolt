import CoreGraphics

/// An area whose original pixels are pixelated or blurred.
struct RedactionAnnotation: AnnotationShape, Hashable {
    var rectInPixels: CGRect
    var mode: RedactionMode
    var strength: Double

    var boundsInPixels: CGRect { rectInPixels }

    var handlePositions: [Handle: CGPoint] { Handle.positions(for: rectInPixels) }

    func contains(_ pointInPixels: CGPoint, toleranceInPixels: CGFloat) -> Bool {
        rectInPixels.insetBy(dx: -toleranceInPixels, dy: -toleranceInPixels).contains(pointInPixels)
    }

    func moved(by offset: CGVector) -> RedactionAnnotation {
        var redaction = self
        redaction.rectInPixels = rectInPixels.offsetBy(dx: offset.dx, dy: offset.dy)
        return redaction
    }

    func resized(dragging handle: Handle, to pointInPixels: CGPoint) -> RedactionAnnotation {
        var redaction = self
        redaction.rectInPixels = RectResizing.resized(rectInPixels, dragging: handle, to: pointInPixels)
        return redaction
    }

    func restyled(_ style: ToolStyle, scale: CGFloat) -> RedactionAnnotation {
        var redaction = self
        redaction.mode = style.redactionMode
        redaction.strength = style.redactionStrength
        return redaction
    }

    func style(applyingTo base: ToolStyle, scale: CGFloat) -> ToolStyle {
        var style = base
        style.redactionMode = mode
        style.redactionStrength = strength
        return style
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rectInPixels.minX)
        hasher.combine(rectInPixels.minY)
        hasher.combine(rectInPixels.width)
        hasher.combine(rectInPixels.height)
        hasher.combine(mode)
        hasher.combine(strength)
    }
}
