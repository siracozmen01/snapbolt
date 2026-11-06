import CoreGraphics

/// Turns a document into the final image.
protocol DocumentExporting: Sendable {
    /// The capture with the document's shapes drawn on it, cropped to its export rect.
    func export(_ document: AnnotationDocument) throws(EditorError) -> CGImage
}
