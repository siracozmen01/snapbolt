import CoreGraphics
import Foundation
import SnapboltCore

/// Draws arrows, rectangles and redaction areas; a press on an existing shape moves or resizes it instead.
struct ShapeDrawingTool: ToolInteraction {
    /// Drags shorter than this in both directions draw nothing.
    static let minimumDragInPoints: CGFloat = 3

    private let tool: EditorTool
    private var selection: SelectionTool?
    private var drawingID: Annotation.ID?
    private var start = CGPoint.zero

    /// Creates the interaction for `.arrow`, `.rectangle` or `.redaction`.
    init(tool: EditorTool) {
        self.tool = tool
    }

    mutating func began(_ input: PointerInput, in state: EditorState) -> EditorState {
        let hit = AnnotationHitTester.hit(
            at: input.pointInPixels, in: state.document, selectedID: state.selectedID,
            toleranceInPixels: input.toleranceInPixels)
        if hit != nil {
            var selection = SelectionTool()
            let next = selection.began(input, in: state)
            self.selection = selection
            return next
        }
        drawingID = UUID()
        start = input.pointInPixels
        var state = state
        state.selectedID = nil
        return state
    }

    mutating func moved(_ input: PointerInput, in state: EditorState) -> EditorState {
        if var selection {
            let next = selection.moved(input, in: state)
            self.selection = selection
            return next
        }
        guard let drawingID, let kind = shape(to: input, style: state.style(for: tool)) else { return state }
        var state = state
        state.document.upsert(Annotation(id: drawingID, kind: kind))
        state.selectedID = drawingID
        return state
    }

    mutating func ended(_ input: PointerInput, in state: EditorState) -> EditorState {
        if var selection {
            self.selection = nil
            return selection.ended(input, in: state)
        }
        var state = moved(input, in: state)
        let minimum = CanvasMapping(scale: input.scale).pixels(fromPoints: Self.minimumDragInPoints)
        let isTiny =
            abs(input.pointInPixels.x - start.x) < minimum && abs(input.pointInPixels.y - start.y) < minimum
        if isTiny, let drawingID {
            state.document.remove(id: drawingID)
            state.selectedID = nil
        }
        drawingID = nil
        return state
    }

    private func shape(to input: PointerInput, style: ToolStyle) -> Annotation.Kind? {
        let end = input.pointInPixels
        let square = input.isShiftDown
        switch tool {
        case .arrow:
            let tip = square ? Self.snappedToFortyFiveDegrees(from: start, to: end) : end
            let arrow = ArrowAnnotation(
                startInPixels: start, endInPixels: tip, color: style.color, lineWidthInPixels: 0)
            return .arrow(arrow.restyled(style, scale: input.scale))
        case .rectangle:
            let rect = RectResizing.rect(from: start, to: end, square: square)
            let rectangle = RectangleAnnotation(
                rectInPixels: rect, color: style.color, lineWidthInPixels: 0, isFilled: false)
            return .rectangle(rectangle.restyled(style, scale: input.scale))
        case .redaction:
            let rect = RectResizing.rect(from: start, to: end, square: square)
            let redaction = RedactionAnnotation(rectInPixels: rect, mode: style.redactionMode, strength: 0)
            return .redaction(redaction.restyled(style, scale: input.scale))
        case .select, .text, .crop:
            return nil
        }
    }

    private static func snappedToFortyFiveDegrees(from start: CGPoint, to end: CGPoint) -> CGPoint {
        let length = hypot(end.x - start.x, end.y - start.y)
        let step = CGFloat.pi / 4
        let angle = (atan2(end.y - start.y, end.x - start.x) / step).rounded() * step
        return CGPoint(x: start.x + cos(angle) * length, y: start.y + sin(angle) * length)
    }
}
