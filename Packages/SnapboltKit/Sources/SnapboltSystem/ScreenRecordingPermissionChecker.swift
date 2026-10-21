import AppKit
import CoreGraphics
import SnapboltCore
import UserNotifications

/// Reads and requests Screen Recording and notification permissions.
public struct ScreenRecordingPermissionChecker: PermissionChecking {
    private static let screenRecordingSettings = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")

    /// Creates a permission checker.
    public init() {}

    /// Whether Screen Recording permission is granted.
    public func hasScreenRecordingPermission() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Shows the system prompt. macOS shows it only once; afterwards the user must use System Settings.
    public func requestScreenRecordingPermission() {
        _ = CGRequestScreenCaptureAccess()
    }

    /// Opens System Settings › Privacy & Security › Screen & System Audio Recording.
    public func openScreenRecordingSettings() {
        guard let url = Self.screenRecordingSettings else { return }
        NSWorkspace.shared.open(url)
    }

    /// Asks for permission to show notifications.
    public func requestNotificationPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            logger.error("Notification authorization failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
