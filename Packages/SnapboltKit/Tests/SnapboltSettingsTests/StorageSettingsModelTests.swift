import Foundation
import SnapboltCore
import SnapboltTestSupport
import Testing

@testable import SnapboltSettings

@MainActor
@Suite("Storage settings model")
struct StorageSettingsModelTests {
    let store = SettingsStore(
        defaults: UserDefaults(suiteName: "snapbolt-tests-\(UUID().uuidString)")!, secrets: InMemorySecretStore())

    func validDraft() -> StorageSettingsDraft {
        StorageSettingsDraft(
            endpoint: "https://acc.r2.cloudflarestorage.com", region: "auto", bucket: "shots", accessKeyID: "KEY",
            secretAccessKey: "SECRET", publicBaseURL: "https://i.example.com", keyTemplate: "{yyyy}/{MM}/{random}")
    }

    @Test("Saving an invalid endpoint shows a message and saves nothing")
    func saveRejectsInvalidEndpointWithMessage() async throws {
        let model = StorageSettingsModel(store: store, tester: FakeConnectionTester(outcome: .success))
        model.draft = validDraft()
        model.draft.endpoint = "https://acc.r2.cloudflarestorage.com/shots"

        #expect(!model.save())
        #expect(
            model.validationMessage
                == "Endpoint must be an https URL without a path, e.g. https://<account-id>.r2.cloudflarestorage.com")
        #expect(try await store.storageSettings() == nil)
    }

    @Test("Saving a valid draft persists it")
    func savePersistsValidDraft() async throws {
        let model = StorageSettingsModel(store: store, tester: FakeConnectionTester(outcome: .success))
        model.draft = validDraft()

        #expect(model.save())
        #expect(model.validationMessage == nil)
        #expect(try await store.storageSettings() == .fixture())
    }

    @Test("Reports a successful connection test")
    func testConnectionReportsSuccess() async {
        let model = StorageSettingsModel(store: store, tester: FakeConnectionTester(outcome: .success))
        model.draft = validDraft()

        await model.testConnection()

        #expect(model.testStatus == .succeeded)
    }

    @Test("Reports the failure message of a connection test")
    func testConnectionReportsFailureMessage() async {
        let model = StorageSettingsModel(store: store, tester: FakeConnectionTester(outcome: .failure(.bucketNotFound)))
        model.draft = validDraft()

        await model.testConnection()

        #expect(model.testStatus == .failed("The bucket was not found. Check the bucket name."))
    }

    @Test("Validates before testing the connection")
    func testConnectionValidatesFirst() async {
        let tester = FakeConnectionTester(outcome: .success)
        let model = StorageSettingsModel(store: store, tester: tester)
        model.draft = validDraft()
        model.draft.keyTemplate = "{yyyy}"

        await model.testConnection()

        #expect(model.testStatus == .failed("The key template must contain {random}."))
        #expect(await tester.testedSettings.isEmpty)
    }

    @Test("Starts from the saved draft")
    func loadsSavedDraft() throws {
        try store.save(.fixture())

        let model = StorageSettingsModel(store: store, tester: FakeConnectionTester(outcome: .success))

        #expect(model.draft == validDraft())
    }
}
