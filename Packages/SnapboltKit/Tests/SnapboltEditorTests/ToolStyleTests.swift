import Foundation
import Testing

@testable import SnapboltEditor

@Suite("Tool style")
struct ToolStyleTests {
    @Test("The standard style matches the spec's defaults")
    func standardMatchesSpec() {
        let style = ToolStyle.standard

        #expect(style.color == .defaultRed)
        #expect(style.lineWidthInPoints == 4)
        #expect(style.fontSizeInPoints == 24)
        #expect(!style.isFilled)
        #expect(!style.hasBackground)
        #expect(style.redactionMode == .pixelate)
        #expect(style.redactionStrength == 40)
    }

    @Test("Clamps sizes and strength to their ranges")
    func clampsToRanges() {
        var low = ToolStyle.standard
        low.lineWidthInPoints = 0
        low.fontSizeInPoints = 2
        low.redactionStrength = 0
        var high = ToolStyle.standard
        high.lineWidthInPoints = 99
        high.fontSizeInPoints = 500
        high.redactionStrength = 150

        #expect(low.clamped().lineWidthInPoints == 1)
        #expect(low.clamped().fontSizeInPoints == 8)
        #expect(low.clamped().redactionStrength == 1)
        #expect(high.clamped().lineWidthInPoints == 40)
        #expect(high.clamped().fontSizeInPoints == 200)
        #expect(high.clamped().redactionStrength == 100)
    }

    @Test("Round-trips through JSON")
    func roundTripsThroughJSON() throws {
        var style = ToolStyle.standard
        style.isFilled = true
        style.redactionMode = .blur

        let data = try JSONEncoder().encode(style)

        #expect(try JSONDecoder().decode(ToolStyle.self, from: data) == style)
    }
}
