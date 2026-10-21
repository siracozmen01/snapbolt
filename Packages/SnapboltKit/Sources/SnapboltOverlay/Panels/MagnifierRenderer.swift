import AppKit
import SnapboltCore

/// Draws a zoomed view of the pixels around the cursor, for pixel-accurate selection.
enum MagnifierRenderer {
    private static let sourcePixels = 11
    private static let zoom: CGFloat = 10
    private static let offset: CGFloat = 20

    static func draw(display: FrozenDisplay, cursor: CGPoint, in context: CGContext, viewBounds: CGRect) {
        let center = CoordinateConversion.pixel(atGlobalPoint: cursor, on: display)
        let half = CGFloat(sourcePixels / 2)
        let source = CGRect(
            x: center.x - half, y: center.y - half, width: CGFloat(sourcePixels), height: CGFloat(sourcePixels))
        guard let zoomed = display.image.cropping(to: source) else { return }
        let side = CGFloat(sourcePixels) * zoom
        let target = placement(
            of: side, near: CoordinateConversion.localPoint(fromGlobalPoint: cursor, on: display), in: viewBounds)
        context.saveGState()
        context.interpolationQuality = .none
        context.draw(zoomed, in: target)
        drawCenterPixelOutline(in: context, target: target)
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(2)
        context.stroke(target)
        context.restoreGState()
    }

    private static func placement(of side: CGFloat, near point: CGPoint, in bounds: CGRect) -> CGRect {
        var origin = CGPoint(x: point.x + offset, y: point.y - offset - side)
        if origin.x + side > bounds.maxX { origin.x = point.x - offset - side }
        if origin.y < bounds.minY { origin.y = point.y + offset }
        return CGRect(origin: origin, size: CGSize(width: side, height: side))
    }

    private static func drawCenterPixelOutline(in context: CGContext, target: CGRect) {
        let index = CGFloat(sourcePixels / 2)
        let pixel = CGRect(x: target.minX + index * zoom, y: target.minY + index * zoom, width: zoom, height: zoom)
        context.setStrokeColor(NSColor.systemRed.cgColor)
        context.setLineWidth(1)
        context.stroke(pixel)
    }
}
