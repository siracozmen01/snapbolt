import CoreGraphics
import Testing

@testable import SnapboltEditor

@Suite("RGBA colour")
struct RGBAColorTests {
    @Test(
        "Round-trips through CGColor",
        arguments: [RGBAColor.defaultRed, RGBAColor(red: 0, green: 0, blue: 1, alpha: 0.5)])
    func roundTripsThroughCGColor(_ color: RGBAColor) throws {
        let converted = try #require(RGBAColor(cgColor: color.cgColor))

        #expect(abs(converted.red - color.red) < 0.001)
        #expect(abs(converted.green - color.green) < 0.001)
        #expect(abs(converted.blue - color.blue) < 0.001)
        #expect(abs(converted.alpha - color.alpha) < 0.001)
    }

    @Test("Classifies light and dark colours")
    func classifiesLightness() {
        #expect(RGBAColor(red: 1, green: 1, blue: 1, alpha: 1).isLight)
        #expect(RGBAColor(red: 1, green: 1, blue: 0, alpha: 1).isLight)
        #expect(!RGBAColor(red: 0, green: 0, blue: 0, alpha: 1).isLight)
        #expect(!RGBAColor.defaultRed.isLight)
    }
}
