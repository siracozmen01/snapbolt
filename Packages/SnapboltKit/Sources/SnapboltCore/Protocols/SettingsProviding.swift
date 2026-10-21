/// Supplies the current settings to the capture workflow.
public protocol SettingsProviding: Sendable {
    /// The storage settings, or `nil` when storage is not fully configured.
    /// - Throws: ``SettingsError``.
    func storageSettings() async throws -> StorageSettings?
    /// The local-copy preferences.
    func capturePreferences() async -> CapturePreferences
}
