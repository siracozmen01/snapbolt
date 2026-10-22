import Foundation
import SnapboltCapture
import SnapboltCore
import SnapboltEditor
import SnapboltHistory
import SnapboltOverlay
import SnapboltSettings
import SnapboltSystem
import SnapboltUpload
import SnapboltWorkflow

/// The composition root: the only place that creates concrete implementations and wires them together.
@MainActor
final class AppEnvironment {
    let settingsStore = SettingsStore()
    let permissions = ScreenRecordingPermissionChecker()
    let history = HistoryStore(fileURL: HistoryStore.defaultFileURL)
    let launchAtLogin = LaunchAtLoginController()
    let connectionTester = S3ConnectionTester()
    let clipboard = PasteboardClipboard()
    let notifier: UserNotificationNotifier
    /// The General settings, shared by the settings window and the menu's Edit After Capture item.
    let generalSettings: GeneralSettingsModel
    let workflow: CaptureWorkflow

    init(onRecovery: @escaping @MainActor @Sendable (Recovery) -> Void) {
        notifier = UserNotificationNotifier(onRecovery: onRecovery)
        generalSettings = GeneralSettingsModel(store: settingsStore, launchAtLogin: launchAtLogin)
        workflow = CaptureWorkflow(
            dependencies: CaptureWorkflow.Dependencies(
                capturer: ScreenCaptureKitCapturer(),
                selector: OverlayController(),
                editor: EditorController(),
                encoder: PNGEncoder(),
                saver: LocalCaptureFileSaver(),
                uploader: S3Uploader(),
                settings: settingsStore,
                clipboard: clipboard,
                notifier: notifier,
                history: history
            )
        )
    }
}
