import CoreGraphics
import Testing

@testable import SnapboltEditor

@Suite("Text tool")
struct TextToolTests {
    @Test("A click places empty text and opens it for editing")
    func placesEmptyTextForEditing() throws {
        var tool = TextTool()

        let state = tool.drag(from: CGPoint(x: 30, y: 40), to: CGPoint(x: 30, y: 40), in: .empty(), scale: 2)

        let annotation = try #require(state.document.annotations.first)
        guard case .text(let text) = annotation.kind else {
            Issue.record("Expected text")
            return
        }
        #expect(text.originInPixels == CGPoint(x: 30, y: 40))
        #expect(text.string.isEmpty)
        #expect(text.fontSizeInPixels == 48)
        #expect(state.selectedID == annotation.id)
        #expect(state.editingTextID == annotation.id)
    }

    @Test("Pressing on existing text moves it")
    func pressOnTextMovesIt() throws {
        let start = EditorState.empty(with: [.text(Samples.text("Hello", at: CGPoint(x: 20, y: 20)))])
        var tool = TextTool()

        let state = tool.drag(from: CGPoint(x: 30, y: 30), to: CGPoint(x: 40, y: 35), in: start)

        #expect(state.document.annotations.count == 1)
        guard case .text(let text) = try #require(state.document.annotations.first).kind else {
            Issue.record("Expected text")
            return
        }
        #expect(text.originInPixels == CGPoint(x: 30, y: 25))
        #expect(state.editingTextID == nil)
    }
}
