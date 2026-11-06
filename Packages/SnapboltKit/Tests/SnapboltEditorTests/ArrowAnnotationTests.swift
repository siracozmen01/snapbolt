import CoreGraphics
import Testing

@testable import SnapboltEditor

@Suite("Arrow annotation")
struct ArrowAnnotationTests {
    @Test("The head grows with the line width but never below 10 px")
    func headSizeFollowsLineWidth() {
        let thin = Samples.arrow(from: .zero, to: CGPoint(x: 100, y: 0), width: 2)
        let thick = Samples.arrow(from: .zero, to: CGPoint(x: 100, y: 0), width: 8)

        #expect(thin.headLengthInPixels == 10)
        #expect(thick.headLengthInPixels == 32)
        #expect(thick.shaftEndInPixels == CGPoint(x: 68, y: 0))
        #expect(thick.headPointsInPixels.first == CGPoint(x: 100, y: 0))
    }

    @Test("Hits within the tolerance plus half the line width of the shaft")
    func hitsNearTheShaft() {
        let arrow = Samples.arrow(from: .zero, to: CGPoint(x: 100, y: 0), width: 4)

        #expect(arrow.contains(CGPoint(x: 50, y: 7), toleranceInPixels: 6))
        #expect(!arrow.contains(CGPoint(x: 50, y: 9), toleranceInPixels: 6))
        #expect(!arrow.contains(CGPoint(x: 120, y: 0), toleranceInPixels: 6))
    }

    @Test("Dragging the end handle moves only the end")
    func dragsEndpoints() {
        let arrow = Samples.arrow(from: .zero, to: CGPoint(x: 100, y: 0))

        let resized = arrow.resized(dragging: .end, to: CGPoint(x: 10, y: 90))

        #expect(resized.startInPixels == .zero)
        #expect(resized.endInPixels == CGPoint(x: 10, y: 90))
        #expect(Set(arrow.handlePositions.keys) == [.start, .end])
    }
}
