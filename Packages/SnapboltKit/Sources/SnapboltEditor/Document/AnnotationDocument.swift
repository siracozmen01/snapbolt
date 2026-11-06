import CoreGraphics

/// Everything the user changed on one capture: the shapes and the crop. The image itself is not part of
/// the document, so whole documents are cheap to keep for undo.
struct AnnotationDocument: Equatable, Sendable {
    let imageSizeInPixels: CGSize
    /// The shapes in drawing order; later entries are drawn on top.
    var annotations: [Annotation] = []
    /// The crop applied on export; `nil` keeps the whole image.
    var cropRectInPixels: CGRect?

    init(imageSizeInPixels: CGSize) {
        self.imageSizeInPixels = imageSizeInPixels
    }

    var imageBoundsInPixels: CGRect { CGRect(origin: .zero, size: imageSizeInPixels) }

    /// The part of the image that is exported.
    var exportRectInPixels: CGRect { cropRectInPixels ?? imageBoundsInPixels }

    func annotation(withID id: Annotation.ID) -> Annotation? {
        annotations.first { $0.id == id }
    }

    /// Replaces the shape with the same id in place, or adds `annotation` on top.
    mutating func upsert(_ annotation: Annotation) {
        if let index = annotations.firstIndex(where: { $0.id == annotation.id }) {
            annotations[index] = annotation
        } else {
            annotations.append(annotation)
        }
    }

    mutating func remove(id: Annotation.ID) {
        annotations.removeAll { $0.id == id }
    }
}
