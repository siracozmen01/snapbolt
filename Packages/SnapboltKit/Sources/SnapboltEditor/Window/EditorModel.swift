import CoreGraphics
import Observation
import SnapboltCore

/// The editor's state and every change to it. Tools compute new states; the model commits them and keeps
/// one undo step per gesture.
@MainActor
@Observable
final class EditorModel {
    /// Where the editor is in its life.
    enum Phase: Equatable {
        case editing
        case exporting
        case confirmingDiscard
        case exportFailed
        case finished
    }

    /// A press grabs shapes and handles within this many screen points.
    static let toleranceInScreenPoints: CGFloat = 6

    /// The current state. Changed only by `EditorModel` and its extensions.
    var state: EditorState
    /// The undo history. Changed only by `EditorModel` and its extensions.
    var history = EditHistory()
    private(set) var mapping: CanvasMapping
    var phase = Phase.editing

    let capture: CapturedImage
    let preferences: ToolStylePreferences
    let exporter: any DocumentExporting
    let onFinish: @MainActor (EditedImage?) -> Void
    @ObservationIgnored private let initialDocument: AnnotationDocument
    @ObservationIgnored private var interaction: (any ToolInteraction)?
    @ObservationIgnored private var documentAtGestureStart: AnnotationDocument?
    /// The document before the open text field's text was placed or opened.
    @ObservationIgnored var documentBeforeTextEdit: AnnotationDocument?

    init(
        capture: CapturedImage, preferences: ToolStylePreferences, exporter: any DocumentExporting,
        onFinish: @escaping @MainActor (EditedImage?) -> Void
    ) {
        let document = AnnotationDocument(
            imageSizeInPixels: CGSize(width: capture.image.width, height: capture.image.height))
        self.capture = capture
        self.preferences = preferences
        self.exporter = exporter
        self.onFinish = onFinish
        initialDocument = document
        state = EditorState(document: document, styles: preferences.load())
        mapping = CanvasMapping(scale: capture.scale)
    }

    var canUndo: Bool { history.canUndo }
    var canRedo: Bool { history.canRedo }
    var hasChanges: Bool { state.document != initialDocument }

    /// The tool whose style controls are shown: the selected shape's, else the active tool's.
    var styleTool: EditorTool { state.selectedAnnotation?.tool ?? state.tool }

    /// The style shown in the toolbar: the selected shape's own values, else the active tool's style.
    var currentStyle: ToolStyle {
        let base = state.style(for: styleTool)
        return state.selectedAnnotation?.style(applyingTo: base, scale: mapping.scale) ?? base
    }

    func setMagnification(_ magnification: CGFloat) {
        mapping.magnification = magnification
    }

    func selectTool(_ tool: EditorTool) {
        state.tool = tool
        if tool == .crop { state.selectedID = nil }
    }

    func pointerDown(atCanvas point: CGPoint, isShiftDown: Bool, clickCount: Int) {
        guard phase == .editing else { return }
        let input = pointerInput(at: point, isShiftDown: isShiftDown, clickCount: clickCount)
        if clickCount == 2, let textID = textHit(at: input) {
            beginEditingText(textID)
            return
        }
        documentAtGestureStart = state.document
        var interaction = state.tool.makeInteraction()
        state = interaction.began(input, in: state)
        self.interaction = interaction
        if state.editingTextID != nil {
            documentBeforeTextEdit = documentAtGestureStart
        }
    }

    func pointerDragged(toCanvas point: CGPoint, isShiftDown: Bool) {
        guard var interaction else { return }
        state = interaction.moved(pointerInput(at: point, isShiftDown: isShiftDown, clickCount: 1), in: state)
        self.interaction = interaction
    }

    func pointerUp(atCanvas point: CGPoint, isShiftDown: Bool) {
        guard var interaction else { return }
        state = interaction.ended(pointerInput(at: point, isShiftDown: isShiftDown, clickCount: 1), in: state)
        self.interaction = nil
        // A newly placed text is recorded when its text is committed, as one step with the typing.
        if state.editingTextID == nil, let before = documentAtGestureStart {
            recordChange(from: before)
        }
        documentAtGestureStart = nil
    }

    /// Records `before` as an undo step if the document has changed since.
    func recordChange(from before: AnnotationDocument) {
        if before != state.document {
            history.record(before)
        }
    }

    private func pointerInput(at point: CGPoint, isShiftDown: Bool, clickCount: Int) -> PointerInput {
        PointerInput(
            pointInPixels: mapping.pixelPoint(fromCanvas: point), isShiftDown: isShiftDown, clickCount: clickCount,
            toleranceInPixels: mapping.pixels(fromScreenPoints: Self.toleranceInScreenPoints), scale: mapping.scale)
    }

    private func textHit(at input: PointerInput) -> Annotation.ID? {
        let hit = AnnotationHitTester.hit(
            at: input.pointInPixels, in: state.document, selectedID: nil, toleranceInPixels: input.toleranceInPixels)
        guard case .body(let id) = hit, case .text = state.document.annotation(withID: id)?.kind else { return nil }
        return id
    }
}
