import CoreGraphics
import SnapboltCore

/// Converts tracker outcomes (global points) into selections (display pixels).
enum SelectionResolver {
    /// Resolves `outcome` on the display under its anchor, clipped to that display.
    /// Returns nil when nothing remains after clipping.
    static func selection(for outcome: TrackerOutcome, in screens: FrozenScreens) -> Selection? {
        switch outcome {
        case .region(let rect, let anchor):
            pixelRect(rect, anchor: anchor, in: screens).map { .region($0.id, rectInPixels: $0.rect) }
        case .window(let window, let anchor):
            pixelRect(window.frameInGlobalPoints, anchor: anchor, in: screens)
                .map { .window($0.id, rectInPixels: $0.rect) }
        }
    }

    /// The whole display under `point`, or nil when the point is on no display.
    static func fullDisplaySelection(at point: CGPoint, in screens: FrozenScreens) -> Selection? {
        screens.display(containing: point).map { .display($0.id) }
    }

    private static func pixelRect(_ rect: CGRect, anchor: CGPoint, in screens: FrozenScreens)
        -> (id: DisplayID, rect: CGRect)?
    {
        guard let display = screens.display(containing: anchor) else { return nil }
        let clipped = rect.intersection(display.frameInGlobalPoints)
        guard !clipped.isNull, !clipped.isEmpty else { return nil }
        let pixels = CoordinateConversion.pixelRect(fromGlobalPoints: clipped, on: display)
        return pixels.isEmpty ? nil : (display.id, pixels)
    }
}
