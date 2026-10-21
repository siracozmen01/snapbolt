import AppKit
import SnapboltCore

/// Shows one frozen display and turns mouse and keyboard input into ``OverlayEvent``s.
final class SelectionView: NSView {
    private enum KeyCode {
        static let escape: UInt16 = 53
        static let returnKey: UInt16 = 36
        static let enter: UInt16 = 76
    }

    let display: FrozenDisplay
    var state = OverlayState() {
        didSet { needsDisplay = true }
    }
    private let onEvent: @MainActor (OverlayEvent) -> Void

    init(display: FrozenDisplay, onEvent: @escaping @MainActor (OverlayEvent) -> Void) {
        self.display = display
        self.onEvent = onEvent
        super.init(frame: CGRect(origin: .zero, size: display.frameInGlobalPoints.size))
        addTrackingArea(
            NSTrackingArea(
                rect: .zero, options: [.mouseMoved, .activeAlways, .inVisibleRect, .cursorUpdate], owner: self))
    }

    @available(*, unavailable, message: "Created in code only")
    required init?(coder: NSCoder) {
        preconditionFailure("SelectionView is never loaded from a nib")
    }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    override func mouseMoved(with event: NSEvent) { onEvent(.moved(globalLocation(of: event))) }
    override func mouseDown(with event: NSEvent) { onEvent(.pressed(globalLocation(of: event))) }
    override func mouseDragged(with event: NSEvent) { onEvent(.dragged(globalLocation(of: event))) }
    override func mouseUp(with event: NSEvent) { onEvent(.released(globalLocation(of: event))) }
    override func rightMouseDown(with event: NSEvent) { onEvent(.cancel) }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case KeyCode.escape:
            onEvent(.cancel)
        case KeyCode.returnKey, KeyCode.enter:
            onEvent(.selectDisplay(NSEvent.mouseLocation))
        default:
            super.keyDown(with: event)
        }
    }

    private func globalLocation(of event: NSEvent) -> CGPoint {
        window?.convertPoint(toScreen: event.locationInWindow) ?? NSEvent.mouseLocation
    }
}
