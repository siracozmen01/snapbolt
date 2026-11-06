import CoreGraphics

/// Selects shapes, moves them by their body and resizes them by the selection's handles.
struct SelectionTool: ToolInteraction {
    private enum Gesture {
        case idle
        case moving(Annotation.ID, from: CGPoint)
        case resizing(Annotation.ID, Handle)
    }

    private var gesture = Gesture.idle

    /// `state` with the selected shape moved by `offset`; unchanged without a selection.
    static func nudged(_ state: EditorState, by offset: CGVector) -> EditorState {
        guard let selected = state.selectedAnnotation else { return state }
        var state = state
        state.document.upsert(selected.moved(by: offset))
        return state
    }

    mutating func began(_ input: PointerInput, in state: EditorState) -> EditorState {
        var state = state
        let hit = AnnotationHitTester.hit(
            at: input.pointInPixels, in: state.document, selectedID: state.selectedID,
            toleranceInPixels: input.toleranceInPixels)
        switch hit {
        case .handle(let id, let handle):
            gesture = .resizing(id, handle)
            state.selectedID = id
        case .body(let id):
            gesture = .moving(id, from: input.pointInPixels)
            state.selectedID = id
        case nil:
            gesture = .idle
            state.selectedID = nil
        }
        return state
    }

    mutating func moved(_ input: PointerInput, in state: EditorState) -> EditorState {
        var state = state
        switch gesture {
        case .idle:
            break
        case .moving(let id, let from):
            guard let annotation = state.document.annotation(withID: id) else { break }
            let offset = CGVector(dx: input.pointInPixels.x - from.x, dy: input.pointInPixels.y - from.y)
            state.document.upsert(annotation.moved(by: offset))
            gesture = .moving(id, from: input.pointInPixels)
        case .resizing(let id, let handle):
            guard let annotation = state.document.annotation(withID: id) else { break }
            state.document.upsert(annotation.resized(dragging: handle, to: input.pointInPixels))
        }
        return state
    }

    mutating func ended(_ input: PointerInput, in state: EditorState) -> EditorState {
        let state = moved(input, in: state)
        gesture = .idle
        return state
    }
}
