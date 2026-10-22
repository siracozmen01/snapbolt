import CoreGraphics

/// Finds what a press on the canvas grabs.
enum AnnotationHitTester {
    /// What a press grabs.
    enum Hit: Equatable {
        /// A handle of the selected shape.
        case handle(Annotation.ID, Handle)
        /// The body of a shape.
        case body(Annotation.ID)
    }

    /// The selected shape's nearest handle within the tolerance, else the topmost shape containing the
    /// point, else `nil`.
    static func hit(
        at pointInPixels: CGPoint, in document: AnnotationDocument, selectedID: Annotation.ID?,
        toleranceInPixels: CGFloat
    ) -> Hit? {
        let selected = selectedID.flatMap { document.annotation(withID: $0) }
        if let selected, let handle = nearestHandle(of: selected, to: pointInPixels, within: toleranceInPixels) {
            return .handle(selected.id, handle)
        }
        let topmost = document.annotations.last { $0.contains(pointInPixels, toleranceInPixels: toleranceInPixels) }
        return topmost.map { .body($0.id) }
    }

    private static func nearestHandle(of annotation: Annotation, to point: CGPoint, within tolerance: CGFloat)
        -> Handle?
    {
        let distances = annotation.handlePositions.map { ($0.key, hypot($0.value.x - point.x, $0.value.y - point.y)) }
        return distances.filter { $0.1 <= tolerance }.min { $0.1 < $1.1 }?.0
    }
}
