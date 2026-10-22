import CoreGraphics

/// A point of a shape the user can drag to change its geometry.
enum Handle: CaseIterable, Hashable, Sendable {
    /// The start of an arrow.
    case start
    /// The end (tip) of an arrow.
    case end
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left

    /// The eight handles of a rect: corners and edge midpoints.
    static let rectHandles: [Handle] = [.topLeft, .top, .topRight, .right, .bottomRight, .bottom, .bottomLeft, .left]

    /// Where each rect handle sits on `rect` (top-left origin, y down).
    static func positions(for rect: CGRect) -> [Handle: CGPoint] {
        [
            .topLeft: CGPoint(x: rect.minX, y: rect.minY),
            .top: CGPoint(x: rect.midX, y: rect.minY),
            .topRight: CGPoint(x: rect.maxX, y: rect.minY),
            .right: CGPoint(x: rect.maxX, y: rect.midY),
            .bottomRight: CGPoint(x: rect.maxX, y: rect.maxY),
            .bottom: CGPoint(x: rect.midX, y: rect.maxY),
            .bottomLeft: CGPoint(x: rect.minX, y: rect.maxY),
            .left: CGPoint(x: rect.minX, y: rect.midY),
        ]
    }
}
