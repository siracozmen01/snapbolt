import CoreGraphics
import CoreImage
import SnapboltTestSupport
import Testing

@testable import SnapboltEditor

@Suite("Redaction renderer")
struct RedactionRendererTests {
    let context = CIContext()

    @Test("Pixelate block size follows the spec's formula")
    func blockSizeFollowsSpecFormula() {
        #expect(abs(RedactionRenderer.blockSizeInPixels(strength: 40, scale: 1) - 15.2) < 0.0001)
        #expect(RedactionRenderer.blockSizeInPixels(strength: 100, scale: 2) == 64)
    }

    @Test("Blur radius follows the spec's formula")
    func blurRadiusFollowsSpecFormula() {
        #expect(abs(RedactionRenderer.blurRadiusInPixels(strength: 1, scale: 1) - 2.23) < 0.0001)
        #expect(RedactionRenderer.blurRadiusInPixels(strength: 100, scale: 2) == 50)
    }

    @Test("A patch has the size of its area", arguments: [RedactionMode.pixelate, .blur])
    func patchHasAreaSize(mode: RedactionMode) throws {
        let renderer = RedactionRenderer(source: .solid(width: 100, height: 100), scale: 1, context: context)

        let patch = try #require(
            renderer.patch(for: Samples.redaction(CGRect(x: 10, y: 10, width: 40, height: 20), mode: mode)))

        #expect(patch.width == 40)
        #expect(patch.height == 20)
    }

    @Test("A patch samples the area under it, not a flipped one", arguments: [RedactionMode.pixelate, .blur])
    func samplesTheAreaUnderTheRedaction(mode: RedactionMode) throws {
        let renderer = RedactionRenderer(source: .split(width: 100, height: 100), scale: 1, context: context)

        let patch = try #require(
            renderer.patch(for: Samples.redaction(CGRect(x: 0, y: 0, width: 100, height: 20), mode: mode)))

        for (x, y) in [(0, 0), (50, 10), (99, 19)] {
            let pixel = patch.pixel(atX: x, y: y)
            #expect(pixel.red > 200 && pixel.blue < 50, "pixel (\(x), \(y)) is \(pixel)")
        }
    }

    @Test("Pixelate turns detail into uniform blocks")
    func pixelateMakesUniformBlocks() throws {
        let renderer = RedactionRenderer(source: .stripes(width: 64, height: 64), scale: 1, context: context)

        let patch = try #require(renderer.patch(for: Samples.redaction(CGRect(x: 0, y: 0, width: 64, height: 64))))

        #expect(patch.pixel(atX: 0, y: 0) == patch.pixel(atX: 14, y: 0))
        #expect(patch.pixel(atX: 0, y: 0) == patch.pixel(atX: 1, y: 14))
    }

    @Test("Caches one patch per area, mode and strength")
    func cachesPatches() {
        let renderer = RedactionRenderer(source: .solid(width: 100, height: 100), scale: 1, context: context)
        let redaction = Samples.redaction(CGRect(x: 10, y: 10, width: 40, height: 20))

        _ = renderer.patch(for: redaction)
        _ = renderer.patch(for: redaction)
        #expect(renderer.cachedPatchCount == 1)

        _ = renderer.patch(for: Samples.redaction(CGRect(x: 10, y: 10, width: 40, height: 20), strength: 90))
        #expect(renderer.cachedPatchCount == 2)
    }
}
