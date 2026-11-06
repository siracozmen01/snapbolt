import Foundation
import SnapboltCore
import SnapboltTestSupport

@testable import SnapboltWorkflow

/// A workflow wired to fakes, with the fakes exposed for assertions.
@MainActor
struct WorkflowHarness {
    nonisolated static let fixedNow = Date(timeIntervalSince1970: 1_792_576_800)
    nonisolated static let display = FrozenDisplay.fixture(width: 100, height: 100)

    let capturer: FakeScreenCapturer
    let selector: FakeSelectionPresenter
    let editor: FakeImageEditor
    let encoder: FakeImageEncoder
    let saver: SpyLocalCaptureSaver
    let uploader: FakeUploader
    let clipboard = SpyClipboard()
    let notifier = SpyNotifier()
    let history = FakeHistoryStore()
    let workflow: CaptureWorkflow

    init(
        capture: Result<FrozenScreens, CaptureError>? = nil,
        display: FrozenDisplay = Self.display,
        selection: Selection? = nil,
        opensEditor: Bool = false,
        editResult: EditedImage? = nil,
        storage: Result<StorageSettings?, SettingsError> = .success(.fixture()),
        upload: Result<UploadResult, UploadError> = .success(Self.result(key: "a.png")),
        saveLocally: Bool = false,
        saveFailure: FileSaveError? = nil,
        suspendUploads: Bool = false
    ) {
        capturer = FakeScreenCapturer(result: capture ?? .success(FrozenScreens(displays: [display], windows: [])))
        selector = FakeSelectionPresenter(result: selection)
        editor = FakeImageEditor(result: editResult)
        encoder = FakeImageEncoder()
        saver = SpyLocalCaptureSaver(failure: saveFailure)
        uploader = FakeUploader(result: upload, suspends: suspendUploads)
        let settings = FakeSettingsProvider(
            storage: storage,
            preferences: CapturePreferences(
                saveLocally: saveLocally, folder: URL(filePath: "/captures"), opensEditor: opensEditor)
        )
        workflow = CaptureWorkflow(
            dependencies: CaptureWorkflow.Dependencies(
                capturer: capturer, selector: selector, editor: editor, encoder: encoder, saver: saver,
                uploader: uploader,
                settings: settings, clipboard: clipboard, notifier: notifier, history: history,
                now: { Self.fixedNow }
            )
        )
    }

    static func result(key: String) -> UploadResult {
        UploadResult(objectKey: key, publicURL: StorageSettings.fixture().publicURL(forObjectKey: key))
    }
}

/// Yields until `condition` holds, so tests can wait for a suspended task to reach a point.
@MainActor
func eventually(_ condition: () async -> Bool) async -> Bool {
    for _ in 0..<1_000 {
        if await condition() { return true }
        await Task.yield()
    }
    return false
}
