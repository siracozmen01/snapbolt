/// The kind of capture a shortcut or menu item starts.
public enum CaptureMode: Sendable {
    /// Select a region or window on the frozen screen.
    case region
    /// Capture the display under the cursor without selection.
    case fullScreen
}
