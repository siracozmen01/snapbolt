/// Everything the editor shows at one moment. Only ``document`` is part of undo; selection, tool and
/// styles are not.
struct EditorState: Equatable, Sendable {
    var document: AnnotationDocument
    var selectedID: Annotation.ID?
    /// The text shape whose text field is open, if any.
    var editingTextID: Annotation.ID?
    var tool: EditorTool = .arrow
    /// The last style used with each tool.
    var styles: [EditorTool: ToolStyle] = [:]

    init(document: AnnotationDocument, styles: [EditorTool: ToolStyle] = [:]) {
        self.document = document
        self.styles = styles
    }

    var selectedAnnotation: Annotation? {
        selectedID.flatMap { document.annotation(withID: $0) }
    }

    func style(for tool: EditorTool) -> ToolStyle {
        styles[tool] ?? .standard
    }
}
