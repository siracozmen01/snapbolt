import CoreGraphics
import Testing

@testable import SnapboltCore

@Suite("Canvas mapping")
struct CanvasMappingTests {
    @Test(
        "Round-trips points between pixels and canvas points",
        arguments: [CGFloat(1), 2], [CGFloat(0.5), 1, 3])
    func roundTripsPoints(scale: CGFloat, magnification: CGFloat) {
        let mapping = CanvasMapping(scale: scale, magnification: magnification)
        let pixel = CGPoint(x: 37, y: 81)

        #expect(mapping.pixelPoint(fromCanvas: mapping.canvasPoint(fromPixel: pixel)) == pixel)
    }

    @Test("Canvas points are pixels divided by the scale")
    func canvasIsPixelsOverScale() {
        let mapping = CanvasMapping(scale: 2)

        #expect(
            mapping.canvasRect(fromPixels: CGRect(x: 10, y: 20, width: 100, height: 50))
                == CGRect(x: 5, y: 10, width: 50, height: 25))
        #expect(
            mapping.pixelRect(fromCanvas: CGRect(x: 5, y: 10, width: 50, height: 25))
                == CGRect(x: 10, y: 20, width: 100, height: 50))
    }

    @Test("Screen tolerances shrink in pixels as the canvas zooms in")
    func screenToleranceShrinksWithZoom() {
        let mapping = CanvasMapping(scale: 2, magnification: 4)

        #expect(mapping.pixels(fromScreenPoints: 6) == 3)
    }

    @Test("Style sizes in points scale to pixels")
    func styleSizesScale() {
        let mapping = CanvasMapping(scale: 2)

        #expect(mapping.pixels(fromPoints: 4) == 8)
        #expect(mapping.points(fromPixels: 8) == 4)
    }
}
