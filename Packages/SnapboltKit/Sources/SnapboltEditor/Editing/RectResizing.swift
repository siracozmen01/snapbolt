import CoreGraphics

/// Pure rect geometry shared by rectangles, redaction areas and the crop frame (top-left origin, y down).
enum RectResizing {
    private static let leftHandles: Set<Handle> = [.topLeft, .left, .bottomLeft]
    private static let rightHandles: Set<Handle> = [.topRight, .right, .bottomRight]
    private static let topHandles: Set<Handle> = [.topLeft, .top, .topRight]
    private static let bottomHandles: Set<Handle> = [.bottomLeft, .bottom, .bottomRight]

    /// `rect` with the edges belonging to `handle` moved to `point`, standardized so dragging past the
    /// opposite edge flips the rect instead of giving it a negative size.
    static func resized(_ rect: CGRect, dragging handle: Handle, to point: CGPoint) -> CGRect {
        var minX = rect.minX
        var minY = rect.minY
        var maxX = rect.maxX
        var maxY = rect.maxY
        if leftHandles.contains(handle) { minX = point.x }
        if rightHandles.contains(handle) { maxX = point.x }
        if topHandles.contains(handle) { minY = point.y }
        if bottomHandles.contains(handle) { maxY = point.y }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY).standardized
    }

    /// The rect spanned by a drag from `start` to `end`; with `square`, a square in the drag's direction
    /// whose side is the larger of the two distances.
    static func rect(from start: CGPoint, to end: CGPoint, square: Bool) -> CGRect {
        guard square else {
            return CGRect(x: start.x, y: start.y, width: end.x - start.x, height: end.y - start.y).standardized
        }
        let side = max(abs(end.x - start.x), abs(end.y - start.y))
        let x = end.x >= start.x ? start.x : start.x - side
        let y = end.y >= start.y ? start.y : start.y - side
        return CGRect(x: x, y: y, width: side, height: side)
    }
}
