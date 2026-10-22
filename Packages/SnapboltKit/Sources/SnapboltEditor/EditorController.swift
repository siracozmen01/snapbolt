import AppKit
import CoreImage
import SnapboltCore

/// Shows the annotation editor for a capture.
@MainActor
public final class EditorController: ImageEditing {
    private let defaults: UserDefaults
    private var openEditors: [UUID: EditorWindowController] = [:]

    /// Creates a controller that remembers tool styles in `defaults`.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Opens a new editor window and returns when it closes.
    public func edit(_ capture: CapturedImage) async -> EditedImage? {
        let id = UUID()
        logger.info("Editor opened for a \(capture.image.width)×\(capture.image.height) px capture")
        // One Core Image context per edit: creating one is expensive, and it is reused for every redaction.
        let redactions = RedactionRenderer(source: capture.image, scale: capture.scale, context: CIContext())
        let renderer = AnnotationRenderer(image: capture.image, redactions: redactions)
        return await withCheckedContinuation { continuation in
            let model = EditorModel(
                capture: capture, preferences: ToolStylePreferences(defaults: defaults),
                exporter: ImageExporter(renderer: renderer)
            ) { [weak self] result in
                self?.openEditors.removeValue(forKey: id)?.close()
                continuation.resume(returning: result)
            }
            let imageSize = model.mapping.canvasRect(fromPixels: model.state.document.imageBoundsInPixels).size
            let visibleFrame =
                EditorWindowController.screenUnderMouse?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
            let controller = EditorWindowController(
                model: model, renderer: renderer,
                layout: EditorWindowLayout.initial(imageSizeInPoints: imageSize, visibleFrame: visibleFrame))
            openEditors[id] = controller
            controller.show()
        }
    }
}
