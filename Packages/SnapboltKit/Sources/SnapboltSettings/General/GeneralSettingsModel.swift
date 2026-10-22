import Foundation
import Observation
import SnapboltCore

/// State and actions of the General settings tab.
@MainActor
@Observable
public final class GeneralSettingsModel {
    /// Whether local copies are saved. Saved as soon as it changes.
    public var saveLocally: Bool {
        didSet { savePreferences() }
    }
    /// The folder for local copies. Saved as soon as it changes.
    public var folder: URL {
        didSet { savePreferences() }
    }
    /// Whether every capture opens in the editor. Saved as soon as it changes.
    public var opensEditor: Bool {
        didSet { savePreferences() }
    }
    /// Whether Snapbolt launches at login.
    public private(set) var launchAtLoginEnabled: Bool
    /// Why the last change failed, if it did.
    public private(set) var errorMessage: String?

    private let store: SettingsStore
    private let launchAtLogin: any LaunchAtLoginControlling

    /// Creates the model from the saved preferences.
    public init(store: SettingsStore, launchAtLogin: any LaunchAtLoginControlling) {
        self.store = store
        self.launchAtLogin = launchAtLogin
        let preferences = store.currentCapturePreferences()
        saveLocally = preferences.saveLocally
        folder = preferences.folder
        opensEditor = preferences.opensEditor
        launchAtLoginEnabled = launchAtLogin.isEnabled
    }

    /// Turns launching at login on or off.
    public func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLogin.setEnabled(enabled)
            errorMessage = nil
        } catch {
            logger.error("Changing the login item failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = String(localized: "Could not change the login item setting.")
        }
        launchAtLoginEnabled = launchAtLogin.isEnabled
    }

    private func savePreferences() {
        store.saveCapturePreferences(
            CapturePreferences(saveLocally: saveLocally, folder: folder, opensEditor: opensEditor))
    }
}
