import CoreGraphics
import Testing

@testable import SnapboltEditor

@Suite("Selection tool")
struct SelectionToolTests {
    let start = EditorState.empty(
        with: [.rectangle(Samples.rectangle(CGRect(x: 20, y: 20, width: 40, height: 40), filled: true))])

    @Test("Selects a shape and moves it")
    func selectsAndMoves() throws {
        var tool = SelectionTool()

        let state = tool.drag(from: CGPoint(x: 30, y: 30), to: CGPoint(x: 40, y: 30), in: start)

        let annotation = try #require(state.document.annotations.first)
        #expect(state.selectedID == annotation.id)
        #expect(annotation.boundsInPixels.minX == start.document.annotations[0].boundsInPixels.minX + 10)
    }

    @Test("Resizes the selection by a handle")
    func resizesByHandle() throws {
        var selected = start
        selected.selectedID = start.document.annotations.first?.id
        var tool = SelectionTool()

        let state = tool.drag(from: CGPoint(x: 60, y: 60), to: CGPoint(x: 80, y: 90), in: selected)

        guard case .rectangle(let rectangle) = try #require(state.document.annotations.first).kind else {
            Issue.record("Expected the rectangle")
            return
        }
        #expect(rectangle.rectInPixels == CGRect(x: 20, y: 20, width: 60, height: 70))
    }

    @Test("Clicking empty canvas clears the selection")
    func clickOnEmptyClearsSelection() {
        var selected = start
        selected.selectedID = start.document.annotations.first?.id
        var tool = SelectionTool()

        let state = tool.drag(from: CGPoint(x: 150, y: 90), to: CGPoint(x: 150, y: 90), in: selected)

        #expect(state.selectedID == nil)
    }

    @Test("Nudges the selection; does nothing without one")
    func nudges() {
        var selected = start
        selected.selectedID = start.document.annotations.first?.id

        let nudged = SelectionTool.nudged(selected, by: CGVector(dx: 0, dy: 10))

        #expect(
            nudged.document.annotations[0].boundsInPixels.minY == start.document.annotations[0].boundsInPixels.minY + 10
        )
        #expect(SelectionTool.nudged(start, by: CGVector(dx: 0, dy: 10)) == start)
    }
}
