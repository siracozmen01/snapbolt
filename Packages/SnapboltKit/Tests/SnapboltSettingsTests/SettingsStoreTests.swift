import Foundation
import SnapboltCore
import SnapboltTestSupport
import Testing

@testable import SnapboltSettings

@Suite("Settings store")
struct SettingsStoreTests {
    let defaults = UserDefaults(suiteName: "snapbolt-tests-\(UUID().uuidString)")!

    @Test("Round-trips settings, keeping the secret out of UserDefaults")
    func roundTripsSettingsThroughStore() async throws {
        let secrets = InMemorySecretStore()
        let store = SettingsStore(defaults: defaults, secrets: secrets)

        try store.save(.fixture())

        #expect(try await store.storageSettings() == .fixture())
        #expect(try secrets.secret(for: "secretAccessKey") == "SECRET")
        #expect(!defaults.dictionaryRepresentation().values.contains { ($0 as? String) == "SECRET" })
    }

    @Test("A missing secret means storage is not configured")
    func missingSecretMeansNotConfigured() async throws {
        let secrets = InMemorySecretStore()
        let store = SettingsStore(defaults: defaults, secrets: secrets)
        try store.save(.fixture())

        try secrets.deleteSecret(for: "secretAccessKey")

        #expect(try await store.storageSettings() == nil)
    }

    @Test("A fresh store has the documented defaults")
    func freshStoreHasDefaults() async throws {
        let store = SettingsStore(defaults: defaults, secrets: InMemorySecretStore())

        let draft = try store.loadDraft()
        let preferences = await store.capturePreferences()

        #expect(draft.region == "auto")
        #expect(draft.keyTemplate == "{yyyy}/{MM}/{random}")
        #expect(draft.endpoint.isEmpty)
        #expect(
            preferences
                == CapturePreferences(saveLocally: true, folder: URL.picturesDirectory.appending(path: "Snapbolt")))
        #expect(try await store.storageSettings() == nil)
    }

    @Test("Saves capture preferences")
    func savesCapturePreferences() async {
        let store = SettingsStore(defaults: defaults, secrets: InMemorySecretStore())
        let preferences = CapturePreferences(saveLocally: false, folder: URL(filePath: "/Users/me/Shots"))

        store.saveCapturePreferences(preferences)

        #expect(await store.capturePreferences() == preferences)
    }

    @Test("Keychain errors propagate")
    func keychainErrorPropagates() async {
        let store = SettingsStore(defaults: defaults, secrets: InMemorySecretStore(failure: .keychain(status: -25293)))

        await #expect(throws: SettingsError.keychain(status: -25293)) {
            try await store.storageSettings()
        }
    }
}
