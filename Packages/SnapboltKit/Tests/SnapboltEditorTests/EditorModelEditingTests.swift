import CoreGraphics
import Testing

@testable import SnapboltEditor

@MainActor
@Suite("Editor model: editing")
struct EditorModelEditingTests {
    @Test("A drag is one undo step")
    func dragIsOneUndoStep() {
        let harness = EditorModelHarness()
        harness.model.selectTool(.rectangle)

        harness.drag(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 160, y: 90), steps: 50)
        harness.model.undo()

        #expect(harness.model.state.document.annotations.isEmpty)
        #expect(!harness.model.canUndo)
    }

    @Test("Placing and typing text is one undo step")
    func textEditIsOneUndoStep() {
        let harness = EditorModelHarness()

        harness.placeText("Hi")
        #expect(harness.model.state.document.annotations.count == 1)
        harness.model.undo()

        #expect(harness.model.state.document.annotations.isEmpty)
    }

    @Test("Empty text is discarded without an undo step")
    func emptyTextIsDiscarded() {
        let harness = EditorModelHarness()

        harness.placeText("")

        #expect(harness.model.state.document.annotations.isEmpty)
        #expect(!harness.model.canUndo)
        #expect(harness.model.state.editingTextID == nil)
    }

    @Test("Restyling applies to the selection in one step and becomes the tool's default")
    func restyleAppliesToSelectionAndSaves() throws {
        let harness = EditorModelHarness(scale: 2)
        let model = harness.model
        harness.drawRectangle()
        var style = model.currentStyle
        style.lineWidthInPoints = 10

        model.applyStyle(style)

        #expect(try lineWidth(of: #require(model.state.selectedAnnotation)) == 20)
        #expect(ToolStylePreferences(defaults: harness.defaults).load()[.rectangle]?.lineWidthInPoints == 10)
        model.undo()
        #expect(try lineWidth(of: #require(model.state.document.annotations.first)) == 8)
    }

    @Test("Undo restores the crop")
    func undoRestoresCrop() {
        let harness = EditorModelHarness()
        harness.model.selectTool(.crop)
        harness.drag(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 60, y: 40))
        #expect(harness.model.state.document.cropRectInPixels != nil)

        harness.model.undo()

        #expect(harness.model.state.document.cropRectInPixels == nil)
    }

    @Test("Converts canvas points to pixels on a scale-2 capture")
    func convertsCanvasPointsAtScaleTwo() throws {
        let harness = EditorModelHarness(scale: 2)

        harness.model.selectTool(.rectangle)
        harness.drag(from: CGPoint(x: 5, y: 5), to: CGPoint(x: 30, y: 20))

        let annotation = try #require(harness.model.state.document.annotations.first)
        #expect(annotation.handlePositions[.topLeft] == CGPoint(x: 10, y: 10))
        #expect(annotation.handlePositions[.bottomRight] == CGPoint(x: 60, y: 40))
    }

    @Test("Double-clicking text with any tool opens it for editing")
    func doubleClickEditsText() {
        let harness = EditorModelHarness()
        harness.placeText("Hello")
        harness.model.selectTool(.arrow)

        harness.model.pointerDown(atCanvas: CGPoint(x: 25, y: 25), isShiftDown: false, clickCount: 2)

        #expect(harness.model.state.editingTextID == harness.model.state.document.annotations.first?.id)
    }

    @Test("Deleting removes the selection in one undo step")
    func deletesSelection() {
        let harness = EditorModelHarness()
        harness.drawRectangle()

        harness.model.deleteSelection()
        #expect(harness.model.state.document.annotations.isEmpty)
        harness.model.undo()

        #expect(harness.model.state.document.annotations.count == 1)
    }

    private func lineWidth(of annotation: Annotation) -> CGFloat? {
        guard case .rectangle(let rectangle) = annotation.kind else { return nil }
        return rectangle.lineWidthInPixels
    }
}
