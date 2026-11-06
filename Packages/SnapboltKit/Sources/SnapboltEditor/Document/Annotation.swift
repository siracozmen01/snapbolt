import Foundation

/// One shape on the capture, identified across edits so it can be selected, moved and restyled.
struct Annotation: Identifiable, Equatable, Sendable {
    /// What the shape is, with its geometry and style.
    enum Kind: Equatable, Sendable {
        case arrow(ArrowAnnotation)
        case rectangle(RectangleAnnotation)
        case text(TextAnnotation)
        case redaction(RedactionAnnotation)
    }

    let id: UUID
    var kind: Kind
}
