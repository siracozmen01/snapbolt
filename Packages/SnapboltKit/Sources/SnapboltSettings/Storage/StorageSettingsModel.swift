import Foundation
import Observation
import SnapboltCore

/// State and actions of the Storage settings tab.
@MainActor
@Observable
public final class StorageSettingsModel {
    /// The progress of a connection test.
    public enum TestStatus: Equatable, Sendable {
        /// No test has run since the last edit.
        case idle
        /// A test is running.
        case testing
        /// The last test passed.
        case succeeded
        /// The last test failed with this message.
        case failed(String)
    }

    /// The fields as currently typed.
    public var draft: StorageSettingsDraft
    /// Why the last save failed, if it did.
    public private(set) var validationMessage: String?
    /// The state of the connection test.
    public private(set) var testStatus = TestStatus.idle

    private let store: SettingsStore
    private let tester: any ConnectionTesting

    /// Creates the model and loads the saved settings.
    public init(store: SettingsStore, tester: any ConnectionTesting) {
        self.store = store
        self.tester = tester
        do {
            draft = try store.loadDraft()
        } catch {
            draft = StorageSettingsDraft(
                endpoint: "", region: "auto", bucket: "", accessKeyID: "", secretAccessKey: "", publicBaseURL: "",
                keyTemplate: ObjectKeyTemplate.defaultTemplate.rawValue)
            validationMessage = SettingsMessages.message(for: error)
        }
    }

    /// Validates and saves the draft. Returns whether it was saved.
    @discardableResult
    public func save() -> Bool {
        do {
            try store.save(try draft.validated())
            validationMessage = nil
            return true
        } catch {
            validationMessage = SettingsMessages.message(for: error)
            return false
        }
    }

    /// Validates the draft and runs a connection test with it, without saving.
    public func testConnection() async {
        let settings: StorageSettings
        do {
            settings = try draft.validated()
        } catch {
            testStatus = .failed(SettingsMessages.message(for: error))
            return
        }
        testStatus = .testing
        switch await tester.testConnection(using: settings) {
        case .success:
            testStatus = .succeeded
        case .failure(let failure):
            testStatus = .failed(failure.message)
        }
    }
}
