import Testing

@testable import SnapboltEditor

@Suite("Tool interaction")
struct ToolInteractionTests {
    @Test("Each tool makes its own interaction")
    func makesTheToolsInteraction() {
        #expect(EditorTool.select.makeInteraction() is SelectionTool)
        #expect(EditorTool.arrow.makeInteraction() is ShapeDrawingTool)
        #expect(EditorTool.rectangle.makeInteraction() is ShapeDrawingTool)
        #expect(EditorTool.redaction.makeInteraction() is ShapeDrawingTool)
        #expect(EditorTool.text.makeInteraction() is TextTool)
        #expect(EditorTool.crop.makeInteraction() is CropTool)
    }
}
