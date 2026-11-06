import CoreGraphics

/// Draws a capture and its shapes into a context whose user space is image pixels with y down. The canvas
/// and the exporter both draw through it, so the export matches what the editor showed.
struct AnnotationRenderer: Sendable {
    let image: CGImage
    let redactions: RedactionRenderer

    func drawImage(in context: CGContext) {
        Self.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height), context: context)
    }

    func draw(_ annotations: [Annotation], in context: CGContext) {
        for annotation in annotations {
            context.saveGState()
            switch annotation.kind {
            case .arrow(let arrow): draw(arrow, in: context)
            case .rectangle(let rectangle): draw(rectangle, in: context)
            case .text(let text): draw(text, in: context)
            case .redaction(let redaction): draw(redaction, in: context)
            }
            context.restoreGState()
        }
    }

    /// Draws `image` upright into `rect` of a y-down context; Core Graphics would otherwise draw it upside down.
    static func draw(_ image: CGImage, in rect: CGRect, context: CGContext) {
        context.saveGState()
        context.translateBy(x: rect.minX, y: rect.maxY)
        context.scaleBy(x: 1, y: -1)
        context.draw(image, in: CGRect(origin: .zero, size: rect.size))
        context.restoreGState()
    }

    private func draw(_ arrow: ArrowAnnotation, in context: CGContext) {
        context.setStrokeColor(arrow.color.cgColor)
        context.setFillColor(arrow.color.cgColor)
        context.setLineWidth(arrow.lineWidthInPixels)
        context.setLineCap(.butt)
        context.move(to: arrow.startInPixels)
        context.addLine(to: arrow.shaftEndInPixels)
        context.strokePath()
        context.addLines(between: arrow.headPointsInPixels)
        context.closePath()
        context.fillPath()
    }

    private func draw(_ rectangle: RectangleAnnotation, in context: CGContext) {
        if rectangle.isFilled {
            context.setFillColor(rectangle.color.cgColor)
            context.fill(rectangle.rectInPixels)
        } else {
            context.setStrokeColor(rectangle.color.cgColor)
            context.setLineWidth(rectangle.lineWidthInPixels)
            context.stroke(rectangle.rectInPixels)
        }
    }

    private func draw(_ text: TextAnnotation, in context: CGContext) {
        if text.hasBackground {
            let box = CGPath(
                roundedRect: text.boundsInPixels, cornerWidth: text.paddingInPixels,
                cornerHeight: text.paddingInPixels, transform: nil)
            let background = text.color.isLight ? CGColor(gray: 0, alpha: 0.6) : CGColor(gray: 1, alpha: 0.8)
            context.setFillColor(background)
            context.addPath(box)
            context.fillPath()
        }
        let origin = CGPoint(
            x: text.originInPixels.x + text.paddingInPixels, y: text.originInPixels.y + text.paddingInPixels)
        text.layout.draw(in: context, at: origin, color: text.color)
    }

    private func draw(_ redaction: RedactionAnnotation, in context: CGContext) {
        let bounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        let area = redaction.rectInPixels.integral.intersection(bounds)
        guard !area.isEmpty else { return }
        guard let patch = redactions.patch(for: redaction) else {
            // Without a patch the area must still be hidden; never show the original pixels.
            context.setFillColor(CGColor(gray: 0, alpha: 1))
            context.fill(area)
            return
        }
        Self.draw(patch, in: area, context: context)
    }
}
