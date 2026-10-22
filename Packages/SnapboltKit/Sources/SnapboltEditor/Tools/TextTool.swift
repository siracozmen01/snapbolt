import Foundation

/// Places new text where the user clicks; a press on an existing shape moves or resizes it instead.
struct TextTool: ToolInteraction {
    private var selection: SelectionTool?

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
        let style = state.style(for: .text)
        let text = TextAnnotation(
            string: "", originInPixels: input.pointInPixels, color: style.color, fontSizeInPixels: 0,
            hasBackground: style.hasBackground
        )
        .restyled(style, scale: input.scale)
        let annotation = Annotation(id: UUID(), kind: .text(text))
        var state = state
        state.document.upsert(annotation)
        state.selectedID = annotation.id
        state.editingTextID = annotation.id
        return state
    }

    mutating func moved(_ input: PointerInput, in state: EditorState) -> EditorState {
        guard var selection else { return state }
        let next = selection.moved(input, in: state)
        self.selection = selection
        return next
    }

    mutating func ended(_ input: PointerInput, in state: EditorState) -> EditorState {
        guard var selection else { return state }
        self.selection = nil
        return selection.ended(input, in: state)
    }
}
