import CoreGraphics
import Testing

@testable import SnapboltEditor

@Suite("Zoom levels")
struct ZoomLevelsTests {
    @Test("Steps to the next level in and out, stopping at the ends")
    func stepsInAndOut() {
        #expect(ZoomLevels.zoomedIn(from: 1) == 1.5)
        #expect(ZoomLevels.zoomedOut(from: 1) == 0.75)
        #expect(ZoomLevels.zoomedIn(from: 8) == 8)
        #expect(ZoomLevels.zoomedOut(from: 0.1) == 0.1)
        #expect(ZoomLevels.zoomedIn(from: 1.2) == 1.5)
    }

    @Test("Fits content into the available space within 10%–800%")
    func fitsContent() {
        #expect(ZoomLevels.fitting(CGSize(width: 2000, height: 1000), in: CGSize(width: 1000, height: 1000)) == 0.5)
        #expect(ZoomLevels.fitting(CGSize(width: 10, height: 10), in: CGSize(width: 1000, height: 1000)) == 8)
    }
}
