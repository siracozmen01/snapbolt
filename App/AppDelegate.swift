import AppKit
import SnapboltCore
import SnapboltHotkeys

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var environment: AppEnvironment?
    private var menuBar: MenuBarController?
    private var hotkeys: HotkeyRegistry?
    private var settingsWindow: SettingsWindowController?
    private let onboardingWindow = OnboardingWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let environment = AppEnvironment { [weak self] recovery in self?.handle(recovery) }
        self.environment = environment
        menuBar = MenuBarController(
            history: environment.history,
            actions: MenuBarController.Actions(
                capture: { [weak self] in self?.capture($0) },
                copyLink: { environment.clipboard.writeURL($0) },
                openCapturesFolder: { [weak self] in self?.openCapturesFolder() },
                openSettings: { [weak self] in self?.showSettings(tab: .storage) },
                isEditorEnabled: { environment.generalSettings.opensEditor },
                toggleEditor: { environment.generalSettings.opensEditor.toggle() }
            )
        )
        let hotkeys = HotkeyRegistry { [weak self] in self?.capture($0) }
        hotkeys.start()
        self.hotkeys = hotkeys
        Task { await menuBar?.refreshRecentUploads() }
        #if DEBUG
            // Lets a developer start a capture from Terminal while debugging; never compiled into releases.
            DistributedNotificationCenter.default().addObserver(
                forName: Notification.Name("io.github.siracozmen01.Snapbolt.debugCapture"), object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.capture(.region) }
            }
        #endif
        if !environment.permissions.hasScreenRecordingPermission() {
            onboardingWindow.show(permissions: environment.permissions) { [weak self] in
                self?.showSettings(tab: .storage)
            }
        }
    }

    private func capture(_ mode: CaptureMode) {
        guard let environment else { return }
        Task {
            await environment.workflow.run(mode)
            await menuBar?.refreshRecentUploads()
        }
    }

    private func handle(_ recovery: Recovery) {
        switch recovery {
        case .openStorageSettings:
            showSettings(tab: .storage)
        case .openPrivacySettings:
            environment?.permissions.openScreenRecordingSettings()
        }
    }

    private func showSettings(tab: SettingsTab) {
        guard let environment else { return }
        let controller = settingsWindow ?? SettingsWindowController(environment: environment)
        settingsWindow = controller
        controller.show(tab: tab)
    }

    private func openCapturesFolder() {
        guard let folder = environment?.settingsStore.currentCapturePreferences().folder else { return }
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            // Opening a missing folder simply fails visibly in Finder; nothing else depends on it.
            NSSound.beep()
        }
        NSWorkspace.shared.open(folder)
    }
}
