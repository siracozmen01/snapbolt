import AppKit
import SnapboltCore
import UserNotifications

/// Shows capture results as notifications. Clicking a link notification opens the link; clicking an
/// error notification runs its recovery action.
public final class UserNotificationNotifier: NSObject, UserNotifying, UNUserNotificationCenterDelegate, Sendable {
    private enum UserInfoKey {
        static let url = "url"
        static let recovery = "recovery"
    }

    private let onRecovery: @MainActor @Sendable (Recovery) -> Void

    /// Creates the notifier and makes it the notification center's delegate.
    public init(onRecovery: @escaping @MainActor @Sendable (Recovery) -> Void) {
        self.onRecovery = onRecovery
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Announces that the link is on the clipboard.
    public func notifyLinkCopied(_ url: URL) async {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Link copied")
        content.body = url.absoluteString
        content.userInfo = [UserInfoKey.url: url.absoluteString]
        await deliver(content)
    }

    /// Shows `error` with its recovery action.
    public func notify(_ error: UserFacingError) async {
        let content = UNMutableNotificationContent()
        content.title = error.title
        content.body = error.message
        if let recovery = error.recovery {
            content.userInfo = [UserInfoKey.recovery: Self.identifier(for: recovery)]
        }
        await deliver(content)
    }

    /// Shows banners even while Snapbolt is the active app (it is, right after the overlay closes).
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }

    /// Opens the link or runs the recovery action of a clicked notification.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let url = (userInfo[UserInfoKey.url] as? String).flatMap(URL.init(string:))
        let recovery = (userInfo[UserInfoKey.recovery] as? String).flatMap(Self.recovery(for:))
        await MainActor.run {
            if let url { NSWorkspace.shared.open(url) }
            if let recovery { onRecovery(recovery) }
        }
    }

    private func deliver(_ content: UNMutableNotificationContent) async {
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Notifications may be turned off; the clipboard already holds the result.
            logger.error("Showing a notification failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func identifier(for recovery: Recovery) -> String {
        switch recovery {
        case .openStorageSettings: "openStorageSettings"
        case .openPrivacySettings: "openPrivacySettings"
        }
    }

    private static func recovery(for identifier: String) -> Recovery? {
        [Recovery.openStorageSettings, .openPrivacySettings].first { Self.identifier(for: $0) == identifier }
    }
}
