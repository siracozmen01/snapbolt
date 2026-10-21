import Foundation
import SnapboltCore
import SnapboltTestSupport
import Testing

@testable import SnapboltSettings

@MainActor
@Suite("General settings model")
struct GeneralSettingsModelTests {
    let store = SettingsStore(
        defaults: UserDefaults(suiteName: "snapbolt-tests-\(UUID().uuidString)")!, secrets: InMemorySecretStore())

    @Test("Turning launch at login on calls the controller")
    func togglingLaunchAtLoginCallsController() {
        let launchAtLogin = FakeLaunchAtLogin()
        let model = GeneralSettingsModel(store: store, launchAtLogin: launchAtLogin)

        model.setLaunchAtLogin(true)

        #expect(launchAtLogin.isEnabled)
        #expect(model.launchAtLoginEnabled)
        #expect(model.errorMessage == nil)
    }

    @Test("A launch at login failure shows a message")
    func launchAtLoginErrorShowsMessage() {
        let launchAtLogin = FakeLaunchAtLogin()
        launchAtLogin.failsOnChange = true
        let model = GeneralSettingsModel(store: store, launchAtLogin: launchAtLogin)

        model.setLaunchAtLogin(true)

        #expect(!model.launchAtLoginEnabled)
        #expect(model.errorMessage == "Could not change the login item setting.")
    }

    @Test("Changing local copy preferences saves them")
    func savesCapturePreferences() {
        let model = GeneralSettingsModel(store: store, launchAtLogin: FakeLaunchAtLogin())

        model.saveLocally = false
        model.folder = URL(filePath: "/Users/me/Shots")

        #expect(
            store.currentCapturePreferences()
                == CapturePreferences(saveLocally: false, folder: URL(filePath: "/Users/me/Shots")))
    }
}
