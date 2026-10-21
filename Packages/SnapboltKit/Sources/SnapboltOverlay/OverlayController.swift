import AppKit
import SnapboltCore

/// Shows frozen screens full screen and lets the user drag a region, click a window or press
/// Return for the whole display.
@MainActor
public final class OverlayController: SelectionPresenting {
    private var panels: [OverlayPanel] = []
    private var tracker = SelectionTracker(windows: [])
    private var screens: FrozenScreens?
    private var continuation: CheckedContinuation<Selection?, Never>?

    /// Creates a controller.
    public init() {}

    /// Shows the overlay on every frozen display and returns the selection, or nil on Escape.
    public func select(on screens: FrozenScreens) async -> Selection? {
        self.screens = screens
        tracker = SelectionTracker(windows: screens.windows)
        panels = screens.displays.map { OverlayPanel(display: $0) { [weak self] in self?.handle($0) } }
        // Taking focus from the frontmost app makes games release the cursor. macOS may decline this
        // activation; the panels are non-activating, so they still appear and receive keys.
        NSApp.activate()
        for panel in panels {
            panel.orderFrontRegardless()
        }
        keyPanel(at: NSEvent.mouseLocation)?.makeKey()
        handle(.moved(NSEvent.mouseLocation))
        for panel in panels {
            let frame = String(describing: panel.frame)
            logger.debug("Overlay panel frame=\(frame, privacy: .public) visible=\(panel.isVisible)")
            logger.debug("Overlay key=\(panel.isKeyWindow) appActive=\(NSApp.isActive)")
            logger.debug("Overlay activeSpace=\(panel.isOnActiveSpace) occlusion=\(panel.occlusionState.rawValue)")
        }
        return await withCheckedContinuation { continuation = $0 }
    }

    private func handle(_ event: OverlayEvent) {
        guard let screens else { return }
        switch event {
        case .moved(let point):
            tracker.mouseMoved(to: point)
            redraw(cursor: point)
        case .pressed(let point):
            tracker.mouseDown(at: point)
            redraw(cursor: point)
        case .dragged(let point):
            tracker.mouseDragged(to: point)
            redraw(cursor: point)
        case .released(let point):
            let selection = tracker.mouseUp(at: point).flatMap { SelectionResolver.selection(for: $0, in: screens) }
            selection.map(finish) ?? redraw(cursor: point)
        case .selectDisplay(let point):
            SelectionResolver.fullDisplaySelection(at: point, in: screens).map(finish)
        case .cancel:
            finish(nil)
        }
    }

    private func redraw(cursor: CGPoint) {
        let state = OverlayState(
            region: tracker.currentRegion, highlight: tracker.highlightedWindow?.frameInGlobalPoints, cursor: cursor)
        for panel in panels {
            panel.selectionView.state = state
        }
        keyPanel(at: cursor)?.makeKey()
    }

    private func keyPanel(at point: CGPoint) -> OverlayPanel? {
        panels.first { $0.frame.contains(point) && !$0.isKeyWindow }
    }

    private func finish(_ selection: Selection?) {
        logger.info("Overlay finished: \(selection == nil ? "cancelled" : "selected", privacy: .public)")
        for panel in panels {
            panel.orderOut(nil)
        }
        panels = []
        screens = nil
        continuation?.resume(returning: selection)
        continuation = nil
    }
}
