import Foundation
import SnapboltCore

extension CaptureWorkflow {
    /// Everything the workflow talks to, as Core protocols.
    public struct Dependencies {
        let capturer: any ScreenCapturing
        let selector: any SelectionPresenting
        let editor: any ImageEditing
        let encoder: any ImageEncoding
        let saver: any LocalCaptureSaving
        let uploader: any Uploading
        let settings: any SettingsProviding
        let clipboard: any ClipboardWriting
        let notifier: any UserNotifying
        let history: any UploadHistoryStoring
        let now: @Sendable () -> Date

        /// Creates the workflow's dependencies.
        public init(
            capturer: any ScreenCapturing,
            selector: any SelectionPresenting,
            editor: any ImageEditing,
            encoder: any ImageEncoding,
            saver: any LocalCaptureSaving,
            uploader: any Uploading,
            settings: any SettingsProviding,
            clipboard: any ClipboardWriting,
            notifier: any UserNotifying,
            history: any UploadHistoryStoring,
            now: @escaping @Sendable () -> Date = Date.init
        ) {
            self.capturer = capturer
            self.selector = selector
            self.editor = editor
            self.encoder = encoder
            self.saver = saver
            self.uploader = uploader
            self.settings = settings
            self.clipboard = clipboard
            self.notifier = notifier
            self.history = history
            self.now = now
        }
    }
}
