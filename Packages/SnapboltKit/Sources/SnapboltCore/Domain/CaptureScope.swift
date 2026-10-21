/// Which displays to freeze.
public enum CaptureScope: Sendable {
    /// Every connected display.
    case allDisplays
    /// Only the display under the mouse cursor.
    case displayUnderCursor
}
