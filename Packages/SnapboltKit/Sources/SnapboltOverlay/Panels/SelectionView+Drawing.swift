import AppKit
import SnapboltCore

extension SelectionView {
    private enum Style {
        static let dimAlpha: CGFloat = 0.4
        static let borderWidth: CGFloat = 1
        static let labelOffset: CGFloat = 8
        static let labelPadding: CGFloat = 4
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.interpolationQuality = .none
        context.draw(display.image, in: bounds)
        let focus = (state.region ?? state.highlight).map {
            CoordinateConversion.localRect(fromGlobalRect: $0, on: display)
        }
        drawDim(in: context, leaving: focus)
        if let focus { drawBorder(around: focus, in: context) }
        guard let cursor = state.cursor, display.frameInGlobalPoints.contains(cursor) else { return }
        if let region = state.region { drawSizeLabel(for: region, near: cursor) }
        MagnifierRenderer.draw(display: display, cursor: cursor, in: context, viewBounds: bounds)
    }

    private func drawDim(in context: CGContext, leaving hole: CGRect?) {
        let path = CGMutablePath()
        path.addRect(bounds)
        if let hole { path.addRect(hole) }
        context.addPath(path)
        context.setFillColor(NSColor.black.withAlphaComponent(Style.dimAlpha).cgColor)
        context.fillPath(using: .evenOdd)
    }

    private func drawBorder(around rect: CGRect, in context: CGContext) {
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(Style.borderWidth)
        context.stroke(rect.insetBy(dx: Style.borderWidth / 2, dy: Style.borderWidth / 2))
    }

    private func drawSizeLabel(for region: CGRect, near cursor: CGPoint) {
        let clipped = region.intersection(display.frameInGlobalPoints)
        let pixels = CoordinateConversion.pixelRect(fromGlobalPoints: clipped, on: display)
        let text = "\(Int(pixels.width)) × \(Int(pixels.height))" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.7),
        ]
        let local = CoordinateConversion.localPoint(fromGlobalPoint: cursor, on: display)
        text.draw(
            at: CGPoint(x: local.x + Style.labelOffset, y: local.y - Style.labelOffset - Style.labelPadding * 4),
            withAttributes: attributes)
    }
}
