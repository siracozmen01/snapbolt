import AppKit
import SnapboltSettings
import SwiftUI

/// Owns the settings window.
@MainActor
final class SettingsWindowController {
    private let navigation = SettingsNavigation()
    private let window: NSWindow

    init(environment: AppEnvironment) {
        let root = SettingsRootView(
            navigation: navigation,
            storage: StorageSettingsModel(store: environment.settingsStore, tester: environment.connectionTester),
            general: GeneralSettingsModel(store: environment.settingsStore, launchAtLogin: environment.launchAtLogin)
        )
        window = NSWindow(contentViewController: NSHostingController(rootView: root))
        window.title = String(localized: "Snapbolt Settings")
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
    }

    /// Shows the window on `tab` and brings Snapbolt to the front.
    func show(tab: SettingsTab) {
        navigation.tab = tab
        if !window.isVisible { window.center() }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}
