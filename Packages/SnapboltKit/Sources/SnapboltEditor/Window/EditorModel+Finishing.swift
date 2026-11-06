import CoreGraphics
import SnapboltCore

extension EditorModel {
    /// Exports the edited image and finishes with it. Runs once; an export failure keeps the editor open.
    func finish(_ destination: EditedImage.Destination) async {
        guard phase == .editing else { return }
        phase = .exporting
        let result = await Self.export(state.document, with: exporter)
        switch result {
        case .success(let image):
            logger.info("Editor finished: \(String(describing: destination), privacy: .public)")
            complete(with: EditedImage(image: image, destination: destination))
        case .failure:
            // Never fall back to the unedited capture: it would reveal what the user redacted.
            logger.error("Exporting the edited image failed")
            phase = .exportFailed
        }
    }

    /// Ends the edit without a result, asking first when there are changes.
    func cancel() {
        guard phase == .editing else { return }
        if hasChanges {
            phase = .confirmingDiscard
        } else {
            logger.info("Editor cancelled")
            complete(with: nil)
        }
    }

    func confirmDiscard() {
        guard phase == .confirmingDiscard else { return }
        logger.info("Editor cancelled after confirming")
        complete(with: nil)
    }

    func keepEditing() {
        guard phase == .confirmingDiscard else { return }
        phase = .editing
    }

    func dismissExportError() {
        guard phase == .exportFailed else { return }
        phase = .editing
    }

    private func complete(with result: EditedImage?) {
        phase = .finished
        onFinish(result)
    }

    // Rendering a large capture is CPU work; being nonisolated keeps it off the main actor.
    private nonisolated static func export(_ document: AnnotationDocument, with exporter: any DocumentExporting) async
        -> Result<CGImage, EditorError>
    {
        do {
            return .success(try exporter.export(document))
        } catch {
            return .failure(error)
        }
    }
}
