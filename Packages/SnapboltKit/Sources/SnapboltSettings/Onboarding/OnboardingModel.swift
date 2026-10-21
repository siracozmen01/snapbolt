import Observation
import SnapboltCore

/// State and actions of the first-launch window.
@MainActor
@Observable
public final class OnboardingModel {
    /// Whether Screen Recording permission is granted.
    public private(set) var hasScreenRecordingPermission: Bool
    /// Whether notifications were allowed, once asked.
    public private(set) var notificationsAllowed: Bool?

    private let permissions: any PermissionChecking
    private let onFinish: @MainActor () -> Void

    /// Creates the model; `onFinish` runs when the user clicks Continue.
    public init(permissions: any PermissionChecking, onFinish: @escaping @MainActor () -> Void) {
        self.permissions = permissions
        self.onFinish = onFinish
        hasScreenRecordingPermission = permissions.hasScreenRecordingPermission()
    }

    /// Re-reads the permission, e.g. when the window becomes active again.
    public func refresh() {
        hasScreenRecordingPermission = permissions.hasScreenRecordingPermission()
    }

    /// Shows the system's Screen Recording prompt.
    public func grantScreenRecording() {
        permissions.requestScreenRecordingPermission()
        refresh()
    }

    /// Opens the Screen Recording page of System Settings.
    public func openScreenRecordingSettings() {
        permissions.openScreenRecordingSettings()
    }

    /// Asks for permission to show notifications.
    public func requestNotifications() async {
        notificationsAllowed = await permissions.requestNotificationPermission()
    }

    /// Closes onboarding.
    public func finish() {
        onFinish()
    }
}
