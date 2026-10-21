import KeyboardShortcuts
import SnapboltCore

/// Registers Snapbolt's global shortcuts and reports which capture they start.
@MainActor
public final class HotkeyRegistry {
    private let onCapture: @MainActor (CaptureMode) -> Void

    /// Creates the registry; `onCapture` runs on every shortcut press.
    public init(onCapture: @escaping @MainActor (CaptureMode) -> Void) {
        self.onCapture = onCapture
    }

    /// Starts listening for the shortcuts.
    public func start() {
        // Key-up, so the shortcut's modifier keys are released before the screen is frozen.
        KeyboardShortcuts.onKeyUp(for: .captureRegion) { [weak self] in self?.onCapture(.region) }
        KeyboardShortcuts.onKeyUp(for: .captureFullScreen) { [weak self] in self?.onCapture(.fullScreen) }
        logger.info("Registered capture shortcuts")
    }
}
