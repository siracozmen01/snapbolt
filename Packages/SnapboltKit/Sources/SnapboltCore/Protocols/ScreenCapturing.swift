/// Freezes displays by capturing them before any Snapbolt UI appears.
public protocol ScreenCapturing: Sendable {
    /// Captures the displays in `scope` and the visible windows.
    /// - Throws: ``CaptureError``.
    func freezeDisplays(_ scope: CaptureScope) async throws -> FrozenScreens
}
