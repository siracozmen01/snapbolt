/// Reads and requests the system permissions Snapbolt needs.
public protocol PermissionChecking: Sendable {
    /// Whether Screen Recording permission is granted.
    func hasScreenRecordingPermission() -> Bool
    /// Asks the system to show the Screen Recording permission prompt.
    func requestScreenRecordingPermission()
    /// Opens the Screen Recording page of System Settings.
    func openScreenRecordingSettings()
    /// Asks for permission to show notifications; returns whether it was granted.
    func requestNotificationPermission() async -> Bool
}
