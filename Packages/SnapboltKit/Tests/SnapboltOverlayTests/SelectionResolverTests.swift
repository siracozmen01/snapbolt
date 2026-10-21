import CoreGraphics
import SnapboltCore
import SnapboltTestSupport
import Testing

@testable import SnapboltOverlay

@Suite("Selection resolver")
struct SelectionResolverTests {
    let main = FrozenDisplay(
        id: DisplayID(rawValue: 1), image: .solid(width: 3024, height: 1964),
        frameInGlobalPoints: CGRect(x: 0, y: 0, width: 1512, height: 982), scale: 2)
    let left = FrozenDisplay(
        id: DisplayID(rawValue: 2), image: .solid(width: 1920, height: 1080),
        frameInGlobalPoints: CGRect(x: -1920, y: 0, width: 1920, height: 1080), scale: 1)
    var screens: FrozenScreens { FrozenScreens(displays: [main, left], windows: []) }

    @Test("A region crossing displays is clipped to the display where the drag started")
    func regionIsClippedToAnchorDisplay() {
        let outcome = TrackerOutcome.region(
            CGRect(x: -100, y: 100, width: 300, height: 100), anchor: CGPoint(x: 50, y: 150))

        let selection = SelectionResolver.selection(for: outcome, in: screens)

        #expect(selection == .region(main.id, rectInPixels: CGRect(x: 0, y: 1564, width: 400, height: 200)))
    }

    @Test("A window spanning displays is clipped to the display where it was clicked")
    func windowSpanningDisplaysIsClippedToClickedDisplay() {
        let window = WindowInfo(
            id: 7, ownerName: nil, title: nil, frameInGlobalPoints: CGRect(x: -200, y: 500, width: 400, height: 300))

        let selection = SelectionResolver.selection(for: .window(window, anchor: CGPoint(x: -50, y: 600)), in: screens)

        #expect(selection == .window(left.id, rectInPixels: CGRect(x: 1720, y: 280, width: 200, height: 300)))
    }

    @Test("Return selects the display under the cursor")
    func returnKeySelectsDisplayUnderCursor() {
        #expect(SelectionResolver.fullDisplaySelection(at: CGPoint(x: -10, y: 10), in: screens) == .display(left.id))
        #expect(SelectionResolver.fullDisplaySelection(at: CGPoint(x: 5000, y: 10), in: screens) == nil)
    }

    @Test("An anchor outside every display resolves to nothing")
    func anchorOutsideDisplaysResolvesToNothing() {
        let outcome = TrackerOutcome.region(
            CGRect(x: 4000, y: 0, width: 50, height: 50), anchor: CGPoint(x: 4000, y: 0))

        #expect(SelectionResolver.selection(for: outcome, in: screens) == nil)
    }
}
