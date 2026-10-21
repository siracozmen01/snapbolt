import CoreGraphics
import SnapboltCore

/// What a finished mouse gesture selected, in AppKit global points.
enum TrackerOutcome: Equatable {
    /// A dragged region; `anchor` is where the drag started.
    case region(CGRect, anchor: CGPoint)
    /// A clicked window; `anchor` is where it was clicked.
    case window(WindowInfo, anchor: CGPoint)
}

/// Turns mouse events on the overlay into a selection. Pure, so it can be unit tested.
struct SelectionTracker {
    /// Movements shorter than this (in points) between mouse down and up count as a click.
    static let clickThreshold: CGFloat = 4

    private let windows: [WindowInfo]
    private var dragStart: CGPoint?
    private var dragCurrent: CGPoint?

    /// The window under the cursor while not dragging.
    private(set) var highlightedWindow: WindowInfo?

    /// The region being dragged, normalised; nil when no drag is in progress.
    var currentRegion: CGRect? {
        guard let dragStart, let dragCurrent, Self.isDrag(from: dragStart, to: dragCurrent) else { return nil }
        return Self.rect(from: dragStart, to: dragCurrent)
    }

    /// Creates a tracker for `windows`, ordered front to back.
    init(windows: [WindowInfo]) {
        self.windows = windows
    }

    mutating func mouseMoved(to point: CGPoint) {
        guard dragStart == nil else { return }
        highlightedWindow = window(at: point)
    }

    mutating func mouseDown(at point: CGPoint) {
        dragStart = point
        dragCurrent = point
        highlightedWindow = window(at: point)
    }

    mutating func mouseDragged(to point: CGPoint) {
        dragCurrent = point
        if currentRegion != nil { highlightedWindow = nil }
    }

    /// Ends the gesture and returns what it selected, or nil when it selected nothing.
    mutating func mouseUp(at point: CGPoint) -> TrackerOutcome? {
        defer {
            dragStart = nil
            dragCurrent = nil
        }
        guard let start = dragStart else { return nil }
        guard Self.isDrag(from: start, to: point) else {
            return window(at: start).map { .window($0, anchor: start) }
        }
        return .region(Self.rect(from: start, to: point), anchor: start)
    }

    private func window(at point: CGPoint) -> WindowInfo? {
        windows.first { $0.frameInGlobalPoints.contains(point) }
    }

    private static func isDrag(from start: CGPoint, to end: CGPoint) -> Bool {
        hypot(end.x - start.x, end.y - start.y) >= clickThreshold
    }

    private static func rect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
    }
}
