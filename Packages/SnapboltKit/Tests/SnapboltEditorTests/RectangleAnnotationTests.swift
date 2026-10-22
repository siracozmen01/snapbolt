import CoreGraphics
import Testing

@testable import SnapboltEditor

@Suite("Rectangle annotation")
struct RectangleAnnotationTests {
    @Test("An outline is hit only near its edges; a filled rect anywhere inside")
    func outlineHitsOnlyNearEdges() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)

        #expect(Samples.rectangle(rect).contains(CGPoint(x: 50, y: 2), toleranceInPixels: 6))
        #expect(!Samples.rectangle(rect).contains(CGPoint(x: 50, y: 50), toleranceInPixels: 6))
        #expect(Samples.rectangle(rect, filled: true).contains(CGPoint(x: 50, y: 50), toleranceInPixels: 6))
    }

    @Test("Styles convert between points and pixels with the capture scale")
    func restylesInPixels() {
        var style = ToolStyle.standard
        style.lineWidthInPoints = 4
        let rectangle = Samples.rectangle(CGRect(x: 0, y: 0, width: 10, height: 10), width: 1)

        let restyled = rectangle.restyled(style, scale: 2)

        #expect(restyled.lineWidthInPixels == 8)
        #expect(restyled.style(applyingTo: .standard, scale: 2).lineWidthInPoints == 4)
    }

    @Test("Has eight handles that resize it")
    func resizesByHandles() {
        let rectangle = Samples.rectangle(CGRect(x: 10, y: 10, width: 100, height: 50))

        #expect(rectangle.handlePositions.count == 8)
        #expect(
            rectangle.resized(dragging: .bottomRight, to: CGPoint(x: 210, y: 110)).rectInPixels
                == CGRect(x: 10, y: 10, width: 200, height: 100))
    }
}
