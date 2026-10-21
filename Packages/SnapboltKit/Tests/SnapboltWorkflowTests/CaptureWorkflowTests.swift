import CoreGraphics
import Foundation
import SnapboltCore
import SnapboltTestSupport
import Testing

@testable import SnapboltWorkflow

@MainActor
@Suite("Capture workflow")
struct CaptureWorkflowTests {
    let region = Selection.region(WorkflowHarness.display.id, rectInPixels: CGRect(x: 10, y: 10, width: 20, height: 20))
    let link = WorkflowHarness.result(key: "a.png").publicURL

    @Test("Region capture uploads and copies the link")
    func regionCaptureUploadsAndCopiesLink() async {
        let harness = WorkflowHarness(selection: region)

        await harness.workflow.run(.region)

        #expect(await harness.capturer.requestedScopes == [.allDisplays])
        #expect(harness.encoder.encodedSizes == [CGSize(width: 20, height: 20)])
        #expect(harness.clipboard.writtenURLs == [link])
        #expect(await harness.history.entries == [HistoryEntry(publicURL: link, uploadedAt: WorkflowHarness.fixedNow)])
        #expect(await harness.notifier.linksCopied == [link])
    }

    @Test("A cancelled selection does nothing")
    func cancelledSelectionDoesNothing() async {
        let harness = WorkflowHarness(selection: nil)

        await harness.workflow.run(.region)

        #expect(harness.encoder.encodedSizes.isEmpty)
        #expect(await harness.uploader.uploadedImages.isEmpty)
        #expect(harness.clipboard.writtenURLs.isEmpty && harness.clipboard.writtenImages.isEmpty)
        #expect(await harness.notifier.errors.isEmpty)
        #expect(await harness.notifier.linksCopied.isEmpty)
    }

    @Test("Full screen capture skips selection")
    func fullScreenSkipsSelection() async {
        let harness = WorkflowHarness()

        await harness.workflow.run(.fullScreen)

        #expect(await harness.capturer.requestedScopes == [.displayUnderCursor])
        #expect(harness.selector.presentationCount == 0)
        #expect(harness.encoder.encodedSizes == [CGSize(width: 100, height: 100)])
    }

    @Test("Without storage settings the image is copied")
    func notConfiguredCopiesImage() async {
        let harness = WorkflowHarness(storage: .success(nil))

        await harness.workflow.run(.fullScreen)

        #expect(await harness.uploader.uploadedImages.isEmpty)
        #expect(harness.clipboard.writtenImages.count == 1)
        #expect(await harness.notifier.errors.map(\.recovery) == [.openStorageSettings])
    }

    @Test("An upload failure copies the image and notifies")
    func uploadFailureCopiesImageAndNotifies() async {
        let harness = WorkflowHarness(
            upload: .failure(.server(statusCode: 403, code: "SignatureDoesNotMatch", message: nil)))

        await harness.workflow.run(.fullScreen)

        #expect(harness.clipboard.writtenImages.count == 1)
        #expect(harness.clipboard.writtenURLs.isEmpty)
        #expect(await harness.notifier.errors.map(\.title) == ["Upload failed"])
        #expect(await harness.history.entries.isEmpty)
    }

    @Test("A Keychain failure copies the image")
    func keychainFailureCopiesImage() async {
        let harness = WorkflowHarness(storage: .failure(.keychain(status: -25300)))

        await harness.workflow.run(.fullScreen)

        #expect(harness.clipboard.writtenImages.count == 1)
        #expect(await harness.notifier.errors.first?.message.contains("-25300") == true)
    }

    @Test("A missing permission notifies with the privacy recovery")
    func permissionDeniedNotifiesWithPrivacyRecovery() async {
        let harness = WorkflowHarness(capture: .failure(.permissionDenied))

        await harness.workflow.run(.region)

        #expect(await harness.notifier.errors.map(\.recovery) == [.openPrivacySettings])
        #expect(harness.clipboard.writtenImages.isEmpty && harness.clipboard.writtenURLs.isEmpty)
        #expect(!harness.workflow.isSelecting)
    }

    @Test("A second region capture while selecting is ignored")
    func secondRegionRunWhileSelectingIsIgnored() async {
        let harness = WorkflowHarness()
        harness.selector.suspends = true
        let first = Task { await harness.workflow.run(.region) }
        #expect(await eventually { harness.selector.presentationCount == 1 })

        await harness.workflow.run(.region)

        #expect(await harness.capturer.requestedScopes.count == 1)
        harness.selector.resume(with: nil)
        await first.value
        #expect(!harness.workflow.isSelecting)
    }

    @Test("A capture can start while an upload is in flight")
    func captureRunsWhileUploadInFlight() async {
        let harness = WorkflowHarness(suspendUploads: true)
        let first = Task { await harness.workflow.run(.fullScreen) }
        #expect(await eventually { await harness.uploader.waitingCount == 1 })

        let second = Task { await harness.workflow.run(.fullScreen) }
        #expect(await eventually { await harness.uploader.waitingCount == 2 })
        await harness.uploader.release()
        await first.value
        await second.value

        #expect(await harness.capturer.requestedScopes.count == 2)
        #expect(harness.clipboard.writtenURLs == [link, link])
    }

    @Test("Saves a local copy when enabled")
    func savesLocallyWhenEnabled() async {
        let harness = WorkflowHarness(saveLocally: true)

        await harness.workflow.run(.fullScreen)

        #expect(harness.saver.savedCaptures.map(\.folder) == [URL(filePath: "/captures")])
        #expect(harness.saver.savedCaptures.map(\.capturedAt) == [WorkflowHarness.fixedNow])
    }

    @Test("Skips the local copy when disabled")
    func skipsLocalSaveWhenDisabled() async {
        let harness = WorkflowHarness(saveLocally: false)

        await harness.workflow.run(.fullScreen)

        #expect(harness.saver.savedCaptures.isEmpty)
    }

    @Test("A failed local save still uploads")
    func localSaveFailureStillUploads() async {
        let harness = WorkflowHarness(saveLocally: true, saveFailure: .writeFailed(path: "/captures/x.png"))

        await harness.workflow.run(.fullScreen)

        #expect(await harness.uploader.uploadedImages.count == 1)
        #expect(await harness.notifier.errors.map(\.title) == ["Could not save the local copy"])
        #expect(await harness.notifier.linksCopied == [link])
    }
}
