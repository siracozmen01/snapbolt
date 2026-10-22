import AppKit
import Observation
import SnapboltCore

/// The scroll view's document view: draws the capture and its shapes, and turns mouse and keyboard input
/// into model calls. Its frame is the image's size in points; the scroll view applies the zoom.
@MainActor
final class EditorCanvasView: NSView {
    let model: EditorModel
    let renderer: AnnotationRenderer
    let onZoom: @MainActor (ZoomCommand) -> Void
    let onFinish: @MainActor (EditedImage.Destination) -> Void
    /// The open text field, while the text tool edits a shape.
    var textField: TextEditingField?

    init(
        model: EditorModel, renderer: AnnotationRenderer, onZoom: @escaping @MainActor (ZoomCommand) -> Void,
        onFinish: @escaping @MainActor (EditedImage.Destination) -> Void
    ) {
        self.model = model
        self.renderer = renderer
        self.onZoom = onZoom
        self.onFinish = onFinish
        let size = model.mapping.canvasRect(fromPixels: model.state.document.imageBoundsInPixels).size
        super.init(frame: CGRect(origin: .zero, size: size))
        observeModel()
    }

    @available(*, unavailable, message: "Created in code only")
    required init?(coder: NSCoder) {
        preconditionFailure("EditorCanvasView is never loaded from a nib")
    }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    /// Closes the text field, if one is open, and commits its text.
    func commitTextEditing() {
        textField?.commit()
    }

    private func observeModel() {
        withObservationTracking {
            _ = model.state
            _ = model.mapping
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in self?.modelDidChange() }
        }
    }

    private func modelDidChange() {
        needsDisplay = true
        window?.invalidateCursorRects(for: self)
        syncTextField()
        observeModel()
    }

    private func syncTextField() {
        let editingID = model.state.editingTextID
        if let field = textField, editingID == nil {
            textField = nil
            field.removeFromSuperview()
        }
        guard textField == nil, let editingID,
            case .text(let text) = model.state.document.annotation(withID: editingID)?.kind
        else { return }
        let field = TextEditingField(text: text, mapping: model.mapping) { [weak self] string in
            self?.closeTextField(committing: string)
        }
        textField = field
        addSubview(field)
        window?.makeFirstResponder(field)
    }

    private func closeTextField(committing string: String) {
        guard let field = textField else { return }
        textField = nil
        field.removeFromSuperview()
        model.commitText(string)
        window?.makeFirstResponder(self)
    }
}
