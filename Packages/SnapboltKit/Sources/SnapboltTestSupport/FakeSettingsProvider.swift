// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation
// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.
import Foundation
import SnapboltCore

/// Returns canned storage settings and capture preferences.
public actor FakeSettingsProvider: SettingsProviding {
    private let storage: Result<StorageSettings?, SettingsError>
    private let preferences: CapturePreferences

    public init(
        storage: Result<StorageSettings?, SettingsError>,
        preferences: CapturePreferences = CapturePreferences(
            saveLocally: false, folder: URL(filePath: "/tmp/snapbolt-tests"))
    ) {
        self.storage = storage
        self.preferences = preferences
    }

    public func storageSettings() async throws -> StorageSettings? {
        try storage.get()
    }

    public func capturePreferences() async -> CapturePreferences {
        preferences
    }
}
