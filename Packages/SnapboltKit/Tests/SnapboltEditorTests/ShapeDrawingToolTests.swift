import CoreGraphics
import Testing

@testable import SnapboltEditor

@Suite("Shape drawing tool")
struct ShapeDrawingToolTests {
    @Test("Draws a rectangle with the tool's style and selects it")
    func drawsAndSelectsRectangle() throws {
        var tool = ShapeDrawingTool(tool: .rectangle)

        let state = tool.drag(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 60, y: 40), in: .empty(), scale: 2)

        let annotation = try #require(state.document.annotations.first)
        guard case .rectangle(let rectangle) = annotation.kind else {
            Issue.record("Expected a rectangle")
            return
        }
        #expect(rectangle.rectInPixels == CGRect(x: 10, y: 10, width: 50, height: 30))
        #expect(rectangle.lineWidthInPixels == 8)
        #expect(state.selectedID == annotation.id)
    }

    @Test("Ignores drags shorter than 3 pt in both directions")
    func ignoresTinyDrags() {
        var tool = ShapeDrawingTool(tool: .rectangle)

        let state = tool.drag(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 14, y: 15), in: .empty(), scale: 2)

        #expect(state.document.annotations.isEmpty)
        #expect(state.selectedID == nil)
    }

    @Test("Shift snaps arrows to 45° steps and keeps their length")
    func snapsArrowToFortyFiveDegrees() throws {
        var flat = ShapeDrawingTool(tool: .arrow)
        var diagonal = ShapeDrawingTool(tool: .arrow)

        let flatState = flat.drag(from: .zero, to: CGPoint(x: 100, y: 10), in: .empty(), shift: true)
        let diagonalState = diagonal.drag(from: .zero, to: CGPoint(x: 50, y: 45), in: .empty(), shift: true)

        guard case .arrow(let flatArrow) = try #require(flatState.document.annotations.first).kind,
            case .arrow(let diagonalArrow) = try #require(diagonalState.document.annotations.first).kind
        else {
            Issue.record("Expected arrows")
            return
        }
        #expect(abs(flatArrow.endInPixels.x - 100.50) < 0.01)
        #expect(abs(flatArrow.endInPixels.y) < 0.01)
        #expect(abs(diagonalArrow.endInPixels.x - diagonalArrow.endInPixels.y) < 0.01)
    }

    @Test("Shift squares redaction areas")
    func squaresRedactionWithShift() throws {
        var tool = ShapeDrawingTool(tool: .redaction)

        let state = tool.drag(from: .zero, to: CGPoint(x: 40, y: 10), in: .empty(), shift: true)

        guard case .redaction(let redaction) = try #require(state.document.annotations.first).kind else {
            Issue.record("Expected a redaction")
            return
        }
        #expect(redaction.rectInPixels == CGRect(x: 0, y: 0, width: 40, height: 40))
    }

    @Test("Pressing on an existing shape moves it instead of drawing")
    func pressOnShapeMovesIt() throws {
        let start = EditorState.empty(
            with: [.rectangle(Samples.rectangle(CGRect(x: 20, y: 20, width: 40, height: 40), filled: true))])
        var tool = ShapeDrawingTool(tool: .arrow)

        let state = tool.drag(from: CGPoint(x: 40, y: 40), to: CGPoint(x: 45, y: 45), in: start)

        #expect(state.document.annotations.count == 1)
        guard case .rectangle(let rectangle) = try #require(state.document.annotations.first).kind else {
            Issue.record("Expected the rectangle")
            return
        }
        #expect(rectangle.rectInPixels.origin == CGPoint(x: 25, y: 25))
    }
}
