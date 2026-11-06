import CoreGraphics
import Testing

@testable import SnapboltEditor

@Suite("Redaction annotation")
struct RedactionAnnotationTests {
    @Test("Is hit anywhere inside its area")
    func hitsAnywhereInside() {
        let redaction = Samples.redaction(CGRect(x: 0, y: 0, width: 100, height: 100))

        #expect(redaction.contains(CGPoint(x: 50, y: 50), toleranceInPixels: 6))
        #expect(!redaction.contains(CGPoint(x: 120, y: 50), toleranceInPixels: 6))
    }

    @Test("Restyling changes mode and strength")
    func restylesModeAndStrength() {
        var style = ToolStyle.standard
        style.redactionMode = .blur
        style.redactionStrength = 90

        let restyled = Samples.redaction(CGRect(x: 0, y: 0, width: 10, height: 10)).restyled(style, scale: 2)

        #expect(restyled.mode == .blur)
        #expect(restyled.strength == 90)
    }
}
