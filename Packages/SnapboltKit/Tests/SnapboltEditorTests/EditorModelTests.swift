import CoreGraphics
import SnapboltCore
import Testing

@testable import SnapboltEditor

@MainActor
@Suite("Editor model: finishing")
struct EditorModelTests {
    @Test("Upload finishes with the exported image")
    func uploadFinishesWithExportedImage() async throws {
        let harness = EditorModelHarness()

        await harness.model.finish(.upload)

        let result = try #require(harness.finishedImage)
        #expect(harness.recorder.results.count == 1)
        #expect(result.image.width == 7 && result.image.height == 5)
        #expect(result.destination == .upload)
        #expect(harness.model.phase == .finished)
    }

    @Test("Copy finishes with the clipboard destination")
    func copyFinishesWithClipboardDestination() async throws {
        let harness = EditorModelHarness()

        await harness.model.finish(.clipboard)

        #expect(try #require(harness.finishedImage).destination == .clipboard)
    }

    @Test("Cancelling without changes finishes with nil")
    func cancelWithoutChangesFinishesWithNil() {
        let harness = EditorModelHarness()

        harness.model.cancel()

        #expect(harness.recorder.results.count == 1)
        #expect(harness.recorder.results[0] == nil)
    }

    @Test("Cancelling with changes asks first")
    func cancelWithChangesAsksFirst() {
        let harness = EditorModelHarness()
        let model = harness.model
        harness.drawRectangle()

        model.cancel()
        #expect(model.phase == .confirmingDiscard)
        #expect(harness.recorder.results.isEmpty)
        model.keepEditing()
        #expect(model.phase == .editing)
        model.cancel()
        model.confirmDiscard()

        #expect(harness.recorder.results.count == 1)
        #expect(harness.recorder.results[0] == nil)
    }

    @Test("An export failure keeps the editor open and never finishes")
    func exportFailureKeepsEditorOpen() async {
        let harness = EditorModelHarness(failingExport: true)

        await harness.model.finish(.upload)
        #expect(harness.model.phase == .exportFailed)
        harness.model.dismissExportError()

        #expect(harness.model.phase == .editing)
        #expect(harness.recorder.results.isEmpty)
    }

    @Test("Finishes exactly once")
    func finishesOnlyOnce() async {
        let harness = EditorModelHarness()

        async let first: Void = harness.model.finish(.upload)
        async let second: Void = harness.model.finish(.upload)
        _ = await (first, second)
        harness.model.cancel()

        #expect(harness.recorder.results.count == 1)
    }
}
