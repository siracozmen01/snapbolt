import CoreGraphics

extension EditorModel {
    /// Sets the style of the tool whose controls are shown, remembers it, and restyles the selected shape.
    func applyStyle(_ style: ToolStyle) {
        let style = style.clamped()
        let tool = styleTool
        state.styles[tool] = style
        preferences.save(style, for: tool)
        guard let selected = state.selectedAnnotation else { return }
        let before = state.document
        state.document.upsert(selected.restyled(style, scale: mapping.scale))
        recordChange(from: before)
    }

    func deleteSelection() {
        guard let id = state.selectedID else { return }
        let before = state.document
        state.document.remove(id: id)
        state.selectedID = nil
        recordChange(from: before)
    }

    func nudgeSelection(by offset: CGVector) {
        let before = state.document
        state = SelectionTool.nudged(state, by: offset)
        recordChange(from: before)
    }

    func undo() {
        guard let previous = history.undo(from: state.document) else { return }
        replaceDocument(with: previous)
    }

    func redo() {
        guard let next = history.redo(from: state.document) else { return }
        replaceDocument(with: next)
    }

    func resetCrop() {
        guard state.document.cropRectInPixels != nil else { return }
        let before = state.document
        state.document.cropRectInPixels = nil
        recordChange(from: before)
    }

    /// Opens the text field for an existing text shape.
    func beginEditingText(_ id: Annotation.ID) {
        documentBeforeTextEdit = state.document
        state.selectedID = id
        state.editingTextID = id
    }

    /// Closes the text field with `string`; empty text removes the shape.
    func commitText(_ string: String) {
        guard let id = state.editingTextID else { return }
        state.editingTextID = nil
        if case .text(var text) = state.document.annotation(withID: id)?.kind, !string.isEmpty {
            text.string = string
            state.document.upsert(Annotation(id: id, kind: .text(text)))
        } else {
            state.document.remove(id: id)
            state.selectedID = nil
        }
        if let before = documentBeforeTextEdit {
            recordChange(from: before)
        }
        documentBeforeTextEdit = nil
    }

    private func replaceDocument(with document: AnnotationDocument) {
        state.document = document
        state.editingTextID = nil
        if let id = state.selectedID, document.annotation(withID: id) == nil {
            state.selectedID = nil
        }
    }
}
