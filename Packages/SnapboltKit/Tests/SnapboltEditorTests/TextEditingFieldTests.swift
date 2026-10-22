import CoreGraphics
import SnapboltCore
import Testing

@testable import SnapboltEditor

@MainActor
@Suite("Text editing field")
struct TextEditingFieldTests {
    @Test("The field covers exactly the text's bounds on the canvas")
    func frameMatchesLayout() {
        let mapping = CanvasMapping(scale: 2)
        let text = Samples.text("Hello", at: CGPoint(x: 40, y: 60), fontSize: 48)

        #expect(
            TextEditingField.frame(for: text, mapping: mapping) == mapping.canvasRect(fromPixels: text.boundsInPixels))
    }
}
