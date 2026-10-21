import AppKit
import SnapboltCore
import SnapboltTestSupport
import Testing

@testable import SnapboltOverlay

@MainActor
@Suite("Overlay panel")
struct OverlayPanelTests {
    @Test("The selection view receives key presses (Escape, Return)")
    func selectionViewIsFirstResponder() {
        let panel = OverlayPanel(display: .fixture()) { _ in }

        #expect(panel.firstResponder === panel.selectionView)
    }

    @Test("The panel covers its display above full-screen apps")
    func coversDisplayAboveFullScreenApps() {
        let display = FrozenDisplay.fixture(width: 300, height: 200)

        let panel = OverlayPanel(display: display) { _ in }

        #expect(panel.frame == display.frameInGlobalPoints)
        #expect(panel.level == .screenSaver)
        #expect(panel.collectionBehavior.contains(.fullScreenAuxiliary))
        #expect(panel.canBecomeKey)
    }

    @Test("The panel shows and takes keys even when macOS declines to activate Snapbolt")
    func doesNotNeedAppActivation() {
        let panel = OverlayPanel(display: .fixture()) { _ in }

        #expect(panel.styleMask.contains(.nonactivatingPanel))
    }
}
