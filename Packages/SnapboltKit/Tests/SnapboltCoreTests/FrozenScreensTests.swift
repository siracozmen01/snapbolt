import CoreGraphics
import SnapboltTestSupport
import Testing

@testable import SnapboltCore

@Suite("Frozen screens")
struct FrozenScreensTests {
    let main = FrozenDisplay(
        id: DisplayID(rawValue: 1),
        image: .solid(width: 3024, height: 1964),
        frameInGlobalPoints: CGRect(x: 0, y: 0, width: 1512, height: 982),
        scale: 2
    )
    let left = FrozenDisplay(
        id: DisplayID(rawValue: 2),
        image: .solid(width: 1920, height: 1080),
        frameInGlobalPoints: CGRect(x: -1920, y: 200, width: 1920, height: 1080),
        scale: 1
    )

    @Test("Finds the display that contains a global point")
    func findsDisplayContainingPoint() {
        let screens = FrozenScreens(displays: [main, left], windows: [])

        #expect(screens.display(containing: CGPoint(x: -10, y: 500))?.id == left.id)
        #expect(screens.display(containing: CGPoint(x: 10, y: 10))?.id == main.id)
        #expect(screens.display(containing: CGPoint(x: 5000, y: 0)) == nil)
    }

    @Test("Finds a display by its identifier")
    func findsDisplayByID() {
        let screens = FrozenScreens(displays: [main, left], windows: [])

        #expect(screens.display(withID: DisplayID(rawValue: 2))?.frameInGlobalPoints == left.frameInGlobalPoints)
        #expect(screens.display(withID: DisplayID(rawValue: 9)) == nil)
    }
}
