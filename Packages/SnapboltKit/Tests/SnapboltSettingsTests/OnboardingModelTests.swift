import SnapboltCore
import SnapboltTestSupport
import Testing

@testable import SnapboltSettings

@MainActor
@Suite("Onboarding model")
struct OnboardingModelTests {
    @Test("Refresh reads the current permission")
    func onboardingRefreshReadsPermission() {
        let permissions = FakePermissionChecker(granted: false)
        let model = OnboardingModel(permissions: permissions, onFinish: {})
        #expect(!model.hasScreenRecordingPermission)

        permissions.setGranted(true)
        model.refresh()

        #expect(model.hasScreenRecordingPermission)
    }

    @Test("Granting asks the system and opening goes to System Settings")
    func grantAndOpenSettings() {
        let permissions = FakePermissionChecker(granted: false)
        let model = OnboardingModel(permissions: permissions, onFinish: {})

        model.grantScreenRecording()
        model.openScreenRecordingSettings()

        #expect(permissions.screenRecordingRequests == 1)
        #expect(permissions.settingsOpened == 1)
    }

    @Test("Finishing calls the completion")
    func finishCallsCompletion() {
        var finished = false
        let model = OnboardingModel(permissions: FakePermissionChecker(granted: true), onFinish: { finished = true })

        model.finish()

        #expect(finished)
    }
}
