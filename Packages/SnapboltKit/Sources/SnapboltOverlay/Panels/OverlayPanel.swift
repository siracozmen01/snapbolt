import AppKit
import SnapboltCore

/// A borderless panel covering one display, above everything including full-screen apps.
final class OverlayPanel: NSPanel {
    let selectionView: SelectionView

    init(display: FrozenDisplay, onEvent: @escaping @MainActor (OverlayEvent) -> Void) {
        selectionView = SelectionView(display: display, onEvent: onEvent)
        // Non-activating: since macOS 14 the system may refuse to activate Snapbolt, and a regular panel of
        // an inactive app is never put on screen. A non-activating panel appears and takes keys regardless.
        super.init(
            contentRect: display.frameInGlobalPoints, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered,
            defer: false)
        level = .screenSaver
        // Without .fullScreenAuxiliary the panel would not appear over a game in native full screen.
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = true
        hasShadow = false
        acceptsMouseMovedEvents = true
        isReleasedWhenClosed = false
        contentView = selectionView
        // Without this the window itself receives Escape and Return and only beeps.
        makeFirstResponder(selectionView)
        setFrame(display.frameInGlobalPoints, display: false)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
