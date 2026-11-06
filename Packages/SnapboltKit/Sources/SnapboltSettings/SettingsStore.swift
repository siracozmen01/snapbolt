import Foundation
import SnapboltCore

/// Reads and writes Snapbolt's settings: preferences in UserDefaults, the secret key in the Keychain.
public struct SettingsStore: SettingsProviding {
    private enum Key {
        static let endpoint = "storage.endpoint"
        static let region = "storage.region"
        static let bucket = "storage.bucket"
        static let accessKeyID = "storage.accessKeyID"
        static let publicBaseURL = "storage.publicBaseURL"
        static let keyTemplate = "storage.keyTemplate"
        static let saveLocally = "capture.saveLocally"
        static let folderPath = "capture.folderPath"
        static let opensEditor = "capture.opensEditor"
        static let secretAccount = "secretAccessKey"
    }

    private static let defaultRegion = "auto"

    private let defaultsBox: UserDefaultsBox
    private let secrets: any SecretStoring

    /// Creates a store backed by `defaults` and the Keychain.
    public init(defaults: UserDefaults = .standard) {
        self.init(defaults: defaults, secrets: KeychainSecretStore())
    }

    init(defaults: UserDefaults, secrets: any SecretStoring) {
        defaultsBox = UserDefaultsBox(defaults: defaults)
        self.secrets = secrets
    }

    private var defaults: UserDefaults { defaultsBox.defaults }

    /// The saved storage settings as editable text, with defaults for empty fields.
    public func loadDraft() throws(SettingsError) -> StorageSettingsDraft {
        StorageSettingsDraft(
            endpoint: defaults.string(forKey: Key.endpoint) ?? "",
            region: defaults.string(forKey: Key.region) ?? Self.defaultRegion,
            bucket: defaults.string(forKey: Key.bucket) ?? "",
            accessKeyID: defaults.string(forKey: Key.accessKeyID) ?? "",
            secretAccessKey: try secrets.secret(for: Key.secretAccount) ?? "",
            publicBaseURL: defaults.string(forKey: Key.publicBaseURL) ?? "",
            keyTemplate: defaults.string(forKey: Key.keyTemplate) ?? ObjectKeyTemplate.defaultTemplate.rawValue
        )
    }

    /// Saves validated storage settings.
    public func save(_ settings: StorageSettings) throws(SettingsError) {
        try secrets.setSecret(settings.secretAccessKey, for: Key.secretAccount)
        defaults.set(settings.endpoint.absoluteString, forKey: Key.endpoint)
        defaults.set(settings.region, forKey: Key.region)
        defaults.set(settings.bucket, forKey: Key.bucket)
        defaults.set(settings.accessKeyID, forKey: Key.accessKeyID)
        defaults.set(settings.publicBaseURL.absoluteString, forKey: Key.publicBaseURL)
        defaults.set(settings.keyTemplate.rawValue, forKey: Key.keyTemplate)
    }

    /// Saves the local-copy preferences.
    public func saveCapturePreferences(_ preferences: CapturePreferences) {
        defaults.set(preferences.saveLocally, forKey: Key.saveLocally)
        defaults.set(preferences.folder.path(percentEncoded: false), forKey: Key.folderPath)
        defaults.set(preferences.opensEditor, forKey: Key.opensEditor)
    }

    /// The storage settings, or nil while any field is still empty.
    public func storageSettings() async throws -> StorageSettings? {
        let draft = try loadDraft()
        guard draft.isComplete else { return nil }
        return try draft.validated()
    }

    /// The capture preferences; by default copies are saved to `~/Pictures/Snapbolt` and the editor is off.
    public func capturePreferences() async -> CapturePreferences {
        currentCapturePreferences()
    }

    /// The local-copy preferences, read synchronously for views.
    public func currentCapturePreferences() -> CapturePreferences {
        let saveLocally = defaults.object(forKey: Key.saveLocally) as? Bool ?? true
        let folder = defaults.string(forKey: Key.folderPath).map { URL(filePath: $0) }
        return CapturePreferences(
            saveLocally: saveLocally, folder: folder ?? URL.picturesDirectory.appending(path: "Snapbolt"),
            opensEditor: defaults.bool(forKey: Key.opensEditor))
    }
}

/// `UserDefaults` is documented as thread-safe but is not marked `Sendable` in the SDK.
private struct UserDefaultsBox: @unchecked Sendable {
    let defaults: UserDefaults
}
