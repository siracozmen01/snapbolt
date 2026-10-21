import CoreGraphics

/// The only place where Snapbolt converts between coordinate spaces.
///
/// See the coordinate spaces table in `docs/architecture.md`.
public enum CoordinateConversion {
    /// Converts a rect in AppKit global points (origin bottom-left of the primary display, y up) to
    /// pixels of `display` (origin top-left, y down), rounded outward and clamped to the image.
    public static func pixelRect(fromGlobalPoints rect: CGRect, on display: FrozenDisplay) -> CGRect {
        let frame = display.frameInGlobalPoints
        let scale = display.scale
        let pixels = CGRect(
            x: (rect.minX - frame.minX) * scale,
            y: (frame.maxY - rect.maxY) * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
        let imageBounds = CGRect(x: 0, y: 0, width: display.image.width, height: display.image.height)
        return pixels.integral.intersection(imageBounds)
    }

    /// Converts Quartz window bounds (origin top-left of the primary display, y down, points) to
    /// AppKit global points.
    public static func globalPointsRect(fromQuartzRect rect: CGRect, primaryDisplayHeight: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: primaryDisplayHeight - rect.maxY, width: rect.width, height: rect.height)
    }

    /// Converts a point in AppKit global points to a point local to `display` (origin bottom-left of
    /// that display, y up).
    public static func localPoint(fromGlobalPoint point: CGPoint, on display: FrozenDisplay) -> CGPoint {
        CGPoint(x: point.x - display.frameInGlobalPoints.minX, y: point.y - display.frameInGlobalPoints.minY)
    }
}
