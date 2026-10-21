import CoreGraphics
import Foundation
import SnapboltCore

/// Runs one capture from shortcut to clipboard: freeze → select → crop → encode → save → upload →
/// clipboard → notify.
///
/// A capture is never lost: whenever no link can be produced, the image itself goes to the clipboard.
@MainActor
public final class CaptureWorkflow {
    private let dependencies: Dependencies

    /// Whether the selection overlay is open; new region captures are ignored meanwhile.
    public private(set) var isSelecting = false

    /// Creates a workflow.
    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    /// Runs a capture. Returns when the capture is finished, cancelled or has failed.
    public func run(_ mode: CaptureMode) async {
        guard !isSelecting else {
            logger.info("Ignoring \(String(describing: mode), privacy: .public) capture: selection already open")
            return
        }
        logger.info("Starting \(String(describing: mode), privacy: .public) capture")
        let capturedAt = dependencies.now()
        let encoded: EncodedImage
        do {
            guard let image = try await capture(mode) else { return }
            encoded = try await Self.encode(image, with: dependencies.encoder)
        } catch {
            logger.error("Capture failed: \(String(describing: error), privacy: .public)")
            await dependencies.notifier.notify(ErrorPresenter.present(error))
            return
        }
        await saveLocalCopy(encoded, capturedAt: capturedAt)
        await uploadAndCopyLink(encoded)
    }

    private func capture(_ mode: CaptureMode) async throws -> CGImage? {
        switch mode {
        case .fullScreen:
            let screens = try await dependencies.capturer.freezeDisplays(.displayUnderCursor)
            guard let display = screens.displays.first else { throw CaptureError.noDisplays }
            return try ImageCropper.crop(screens, to: .display(display.id))
        case .region:
            isSelecting = true
            defer { isSelecting = false }
            let screens = try await dependencies.capturer.freezeDisplays(.allDisplays)
            logger.info("Froze \(screens.displays.count) display(s), \(screens.windows.count) window(s)")
            guard let selection = await dependencies.selector.select(on: screens) else {
                logger.info("Selection cancelled")
                return nil
            }
            return try ImageCropper.crop(screens, to: selection)
        }
    }

    private func saveLocalCopy(_ image: EncodedImage, capturedAt: Date) async {
        let preferences = await dependencies.settings.capturePreferences()
        guard preferences.saveLocally else { return }
        do {
            try await Self.save(image, capturedAt: capturedAt, in: preferences.folder, with: dependencies.saver)
        } catch {
            logger.error("Saving the local copy failed: \(String(describing: error), privacy: .private)")
            await dependencies.notifier.notify(ErrorPresenter.present(error))
        }
    }

    private func uploadAndCopyLink(_ image: EncodedImage) async {
        do {
            guard let settings = try await dependencies.settings.storageSettings() else {
                dependencies.clipboard.writeImage(image)
                await dependencies.notifier.notify(ErrorPresenter.notConfigured)
                return
            }
            let result = try await dependencies.uploader.upload(image, using: settings)
            dependencies.clipboard.writeURL(result.publicURL)
            await recordInHistory(result)
            await dependencies.notifier.notifyLinkCopied(result.publicURL)
        } catch {
            logger.error("Upload failed: \(String(describing: error), privacy: .private)")
            dependencies.clipboard.writeImage(image)
            await dependencies.notifier.notify(ErrorPresenter.present(error))
        }
    }

    private func recordInHistory(_ result: UploadResult) async {
        do {
            try await dependencies.history.add(
                HistoryEntry(publicURL: result.publicURL, uploadedAt: dependencies.now()))
        } catch {
            // The link is already on the clipboard; a missing history entry is not worth interrupting the user.
            logger.error("Recording the upload in history failed: \(String(describing: error), privacy: .public)")
        }
    }

    // Encoding and file writes are CPU and disk work; being nonisolated keeps them off the main actor.
    private nonisolated static func encode(_ image: CGImage, with encoder: any ImageEncoding) async throws
        -> EncodedImage
    {
        try encoder.encodePNG(image)
    }

    private nonisolated static func save(
        _ image: EncodedImage, capturedAt: Date, in folder: URL, with saver: any LocalCaptureSaving
    ) async throws {
        _ = try saver.save(image, capturedAt: capturedAt, in: folder)
    }
}
