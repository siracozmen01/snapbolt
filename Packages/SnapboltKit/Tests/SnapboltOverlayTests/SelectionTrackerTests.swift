import CoreGraphics
import SnapboltCore
import Testing

@testable import SnapboltOverlay

@Suite("Selection tracker")
struct SelectionTrackerTests {
    let front = WindowInfo(
        id: 1, ownerName: "Front", title: nil, frameInGlobalPoints: CGRect(x: 50, y: 50, width: 200, height: 200))
    let back = WindowInfo(
        id: 2, ownerName: "Back", title: nil, frameInGlobalPoints: CGRect(x: 0, y: 0, width: 400, height: 400))

    @Test("A drag produces a normalised region anchored at the start")
    func dragProducesNormalisedRegion() {
        var tracker = SelectionTracker(windows: [front, back])

        tracker.mouseDown(at: CGPoint(x: 100, y: 100))
        tracker.mouseDragged(to: CGPoint(x: 40, y: 160))
        let outcome = tracker.mouseUp(at: CGPoint(x: 40, y: 160))

        #expect(outcome == .region(CGRect(x: 40, y: 100, width: 60, height: 60), anchor: CGPoint(x: 100, y: 100)))
    }

    @Test("Shows the current region while dragging")
    func showsCurrentRegionWhileDragging() {
        var tracker = SelectionTracker(windows: [])

        tracker.mouseDown(at: CGPoint(x: 10, y: 10))
        tracker.mouseDragged(to: CGPoint(x: 30, y: 50))

        #expect(tracker.currentRegion == CGRect(x: 10, y: 10, width: 20, height: 40))
    }

    @Test("A click selects the frontmost window under the cursor")
    func clickSelectsFrontmostWindowUnderCursor() {
        var tracker = SelectionTracker(windows: [front, back])

        tracker.mouseDown(at: CGPoint(x: 100, y: 100))
        let outcome = tracker.mouseUp(at: CGPoint(x: 100, y: 100))

        #expect(outcome == .window(front, anchor: CGPoint(x: 100, y: 100)))
    }

    @Test("A click on the empty desktop keeps the overlay open")
    func clickOnEmptyDesktopKeepsOverlayOpen() {
        var tracker = SelectionTracker(windows: [front])

        tracker.mouseDown(at: CGPoint(x: 900, y: 900))

        #expect(tracker.mouseUp(at: CGPoint(x: 900, y: 900)) == nil)
    }

    @Test("A drag shorter than the threshold counts as a click")
    func tinyDragCountsAsClick() {
        var tracker = SelectionTracker(windows: [front, back])

        tracker.mouseDown(at: CGPoint(x: 100, y: 100))
        tracker.mouseDragged(to: CGPoint(x: 103, y: 100))
        let outcome = tracker.mouseUp(at: CGPoint(x: 103, y: 100))

        #expect(outcome == .window(front, anchor: CGPoint(x: 100, y: 100)))
        #expect(tracker.currentRegion == nil)
    }

    @Test("Hover highlights a window; dragging clears the highlight")
    func hoverHighlightsWindowAndClearsDuringDrag() {
        var tracker = SelectionTracker(windows: [front, back])

        tracker.mouseMoved(to: CGPoint(x: 300, y: 300))
        #expect(tracker.highlightedWindow == back)

        tracker.mouseDown(at: CGPoint(x: 10, y: 10))
        tracker.mouseDragged(to: CGPoint(x: 100, y: 100))
        #expect(tracker.highlightedWindow == nil)
    }
}
