import CoreGraphics

extension Annotation {
    /// The tool that draws this kind of shape; its style controls apply to the shape when selected.
    var tool: EditorTool {
        switch kind {
        case .arrow: .arrow
        case .rectangle: .rectangle
        case .text: .text
        case .redaction: .redaction
        }
    }

    var boundsInPixels: CGRect { shape.boundsInPixels }

    var handlePositions: [Handle: CGPoint] { shape.handlePositions }

    func contains(_ pointInPixels: CGPoint, toleranceInPixels: CGFloat) -> Bool {
        shape.contains(pointInPixels, toleranceInPixels: toleranceInPixels)
    }

    func style(applyingTo base: ToolStyle, scale: CGFloat) -> ToolStyle {
        shape.style(applyingTo: base, scale: scale)
    }

    func moved(by offset: CGVector) -> Annotation {
        var annotation = self
        switch kind {
        case .arrow(let arrow): annotation.kind = .arrow(arrow.moved(by: offset))
        case .rectangle(let rectangle): annotation.kind = .rectangle(rectangle.moved(by: offset))
        case .text(let text): annotation.kind = .text(text.moved(by: offset))
        case .redaction(let redaction): annotation.kind = .redaction(redaction.moved(by: offset))
        }
        return annotation
    }

    func resized(dragging handle: Handle, to pointInPixels: CGPoint) -> Annotation {
        var annotation = self
        switch kind {
        case .arrow(let arrow): annotation.kind = .arrow(arrow.resized(dragging: handle, to: pointInPixels))
        case .rectangle(let rectangle):
            annotation.kind = .rectangle(rectangle.resized(dragging: handle, to: pointInPixels))
        case .text(let text): annotation.kind = .text(text.resized(dragging: handle, to: pointInPixels))
        case .redaction(let redaction):
            annotation.kind = .redaction(redaction.resized(dragging: handle, to: pointInPixels))
        }
        return annotation
    }

    func restyled(_ style: ToolStyle, scale: CGFloat) -> Annotation {
        var annotation = self
        switch kind {
        case .arrow(let arrow): annotation.kind = .arrow(arrow.restyled(style, scale: scale))
        case .rectangle(let rectangle): annotation.kind = .rectangle(rectangle.restyled(style, scale: scale))
        case .text(let text): annotation.kind = .text(text.restyled(style, scale: scale))
        case .redaction(let redaction): annotation.kind = .redaction(redaction.restyled(style, scale: scale))
        }
        return annotation
    }

    private var shape: any AnnotationShape {
        switch kind {
        case .arrow(let arrow): arrow
        case .rectangle(let rectangle): rectangle
        case .text(let text): text
        case .redaction(let redaction): redaction
        }
    }
}
