import CoreGraphics
import Foundation
import SnapboltCore
import SnapboltTestSupport
import Testing

@testable import SnapboltWorkflow

@MainActor
@Suite("Capture workflow: editor")
struct CaptureWorkflowEditingTests {
    let region = Selection.region(WorkflowHarness.display.id, rectInPixels: CGRect(x: 10, y: 10, width: 20, height: 20))
    let link = WorkflowHarness.result(key: "a.png").publicURL
    let edited = CGImage.solid(width: 7, height: 5)

    @Test("With the editor off, the editor is never opened")
    func editorOffNeverOpensEditor() async {
        let harness = WorkflowHarness(selection: region)

        await harness.workflow.run(.region)

        #expect(harness.editor.receivedCaptures.isEmpty)
        #expect(harness.clipboard.writtenURLs == [link])
    }

    @Test("Upload continues with the edited image")
    func uploadsEditedImage() async {
        let harness = WorkflowHarness(
            selection: region, opensEditor: true, editResult: EditedImage(image: edited, destination: .upload))

        await harness.workflow.run(.region)

        #expect(harness.editor.receivedCaptures.map(\.image.width) == [20])
        #expect(harness.encoder.encodedSizes == [CGSize(width: 7, height: 5)])
        #expect(harness.clipboard.writtenURLs == [link])
        #expect(await harness.history.entries.count == 1)
    }

    @Test("Copy saves and copies the image without uploading")
    func copyOnlySkipsUpload() async {
        let harness = WorkflowHarness(
            selection: region, opensEditor: true, editResult: EditedImage(image: edited, destination: .clipboard),
            saveLocally: true)

        await harness.workflow.run(.region)

        #expect(harness.clipboard.writtenImages.count == 1)
        #expect(harness.clipboard.writtenURLs.isEmpty)
        #expect(await harness.uploader.uploadedImages.isEmpty)
        #expect(await harness.history.entries.isEmpty)
        #expect(harness.saver.savedCaptures.count == 1)
        #expect(await harness.notifier.errors.isEmpty)
        #expect(await harness.notifier.linksCopied.isEmpty)
    }

    @Test("A cancelled edit leaves no trace")
    func cancelledEditLeavesNoTrace() async {
        let harness = WorkflowHarness(selection: region, opensEditor: true, editResult: nil, saveLocally: true)

        await harness.workflow.run(.region)

        #expect(harness.editor.receivedCaptures.count == 1)
        #expect(harness.encoder.encodedSizes.isEmpty)
        #expect(harness.saver.savedCaptures.isEmpty)
        #expect(await harness.uploader.uploadedImages.isEmpty)
        #expect(harness.clipboard.writtenURLs.isEmpty && harness.clipboard.writtenImages.isEmpty)
        #expect(await harness.notifier.errors.isEmpty)
        #expect(await harness.notifier.linksCopied.isEmpty)
    }

    @Test("Full-screen captures open the editor too")
    func fullScreenOpensEditor() async {
        let harness = WorkflowHarness(opensEditor: true, editResult: EditedImage(image: edited, destination: .upload))

        await harness.workflow.run(.fullScreen)

        #expect(harness.editor.receivedCaptures.map(\.image.width) == [100])
    }

    @Test("The editor receives the selected display's scale")
    func passesDisplayScale() async {
        let harness = WorkflowHarness(
            display: .fixture(width: 200, height: 200, scale: 2), selection: region, opensEditor: true,
            editResult: EditedImage(image: edited, destination: .upload))

        await harness.workflow.run(.region)

        #expect(harness.editor.receivedCaptures.map(\.scale) == [2])
    }

    @Test("Two editors open at once finish independently")
    func twoEditorsFinishIndependently() async {
        let harness = WorkflowHarness(opensEditor: true)
        harness.editor.suspends = true

        let first = Task { await harness.workflow.run(.fullScreen) }
        #expect(await eventually { harness.editor.receivedCaptures.count == 1 })
        let second = Task { await harness.workflow.run(.fullScreen) }
        #expect(await eventually { harness.editor.receivedCaptures.count == 2 })
        harness.editor.resumeNext(with: EditedImage(image: edited, destination: .upload))
        harness.editor.resumeNext(with: EditedImage(image: edited, destination: .upload))
        await first.value
        await second.value

        #expect(harness.clipboard.writtenURLs == [link, link])
    }
}
