import CoreGraphics
import SnapboltTestSupport
import Testing

@testable import SnapboltCore

@Suite("Coordinate conversion")
struct CoordinateConversionTests {
    /// Retina main display, 1512×982 pt at scale 2.
    let main = FrozenDisplay(
        id: DisplayID(rawValue: 1),
        image: .solid(width: 3024, height: 1964),
        frameInGlobalPoints: CGRect(x: 0, y: 0, width: 1512, height: 982),
        scale: 2
    )
    /// External display placed left of and above the main one.
    let aboveLeft = FrozenDisplay(
        id: DisplayID(rawValue: 2),
        image: .solid(width: 1920, height: 1080),
        frameInGlobalPoints: CGRect(x: -1920, y: 982, width: 1920, height: 1080),
        scale: 1
    )

    @Test("Converts a Retina rect to top-left pixels")
    func convertsRetinaRectToTopLeftPixels() {
        let rect = CoordinateConversion.pixelRect(
            fromGlobalPoints: CGRect(x: 100, y: 782, width: 50, height: 100), on: main)

        #expect(rect == CGRect(x: 200, y: 200, width: 100, height: 200))
    }

    @Test("Converts a rect on a display with a negative origin")
    func convertsRectOnDisplayWithNegativeOrigin() {
        let rect = CoordinateConversion.pixelRect(
            fromGlobalPoints: CGRect(x: -1900, y: 2000, width: 100, height: 50), on: aboveLeft)

        #expect(rect == CGRect(x: 20, y: 12, width: 100, height: 50))
    }

    @Test("Clamps a rect to the display image")
    func clampsRectToDisplayBounds() {
        let rect = CoordinateConversion.pixelRect(
            fromGlobalPoints: CGRect(x: 1500, y: 0, width: 50, height: 50), on: main)

        #expect(rect == CGRect(x: 3000, y: 1864, width: 24, height: 100))
    }

    @Test("Rounds fractional points outward to whole pixels")
    func roundsOutwardToWholePixels() {
        let rect = CoordinateConversion.pixelRect(
            fromGlobalPoints: CGRect(x: 0.25, y: 0, width: 10, height: 10), on: atOrigin(aboveLeft))

        #expect(rect == CGRect(x: 0, y: 1070, width: 11, height: 10))
    }

    @Test("Converts Quartz window bounds to AppKit global points")
    func convertsQuartzWindowBoundsToGlobalPoints() {
        let rect = CoordinateConversion.globalPointsRect(
            fromQuartzRect: CGRect(x: 10, y: 20, width: 300, height: 200), primaryDisplayHeight: 982)

        #expect(rect == CGRect(x: 10, y: 762, width: 300, height: 200))
    }

    @Test("Converts a global point to a point local to the display")
    func convertsGlobalPointToLocalPoint() {
        let point = CoordinateConversion.localPoint(fromGlobalPoint: CGPoint(x: -1900, y: 2000), on: aboveLeft)

        #expect(point == CGPoint(x: 20, y: 1018))
    }

    @Test("Converts a global rect to a rect local to the display")
    func convertsGlobalRectToLocalRect() {
        let rect = CoordinateConversion.localRect(
            fromGlobalRect: CGRect(x: -1900, y: 2000, width: 100, height: 50), on: aboveLeft)

        #expect(rect == CGRect(x: 20, y: 1018, width: 100, height: 50))
    }

    @Test("Converts a global point to the display pixel under it")
    func convertsGlobalPointToPixel() {
        let pixel = CoordinateConversion.pixel(atGlobalPoint: CGPoint(x: 100.3, y: 781.6), on: main)

        #expect(pixel == CGPoint(x: 200, y: 400))
    }

    private func atOrigin(_ display: FrozenDisplay) -> FrozenDisplay {
        var frame = display.frameInGlobalPoints
        frame.origin = .zero
        return FrozenDisplay(id: display.id, image: display.image, frameInGlobalPoints: frame, scale: 1)
    }
}
