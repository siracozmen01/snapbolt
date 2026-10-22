import AppKit

extension EditorCanvasView {
    /// Handles are this many points wide on screen at any zoom.
    private static let handleSizeInScreenPoints: CGFloat = 8

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        // The view is flipped (y down) and measured in points; scaling by 1 / scale gives image pixels.
        let scale = model.mapping.scale
        context.scaleBy(x: 1 / scale, y: 1 / scale)
        context.interpolationQuality =
            model.mapping.magnification > ZoomLevels.nearestNeighbourAbove ? .none : .default
        renderer.drawImage(in: context)
        // The open text field shows the text being edited, so the shape itself is not drawn twice.
        let visible = model.state.document.annotations.filter { $0.id != model.state.editingTextID }
        renderer.draw(visible, in: context)
        drawCropMask(in: context)
        context.restoreGState()
        drawSelection(in: context)
    }

    private func drawCropMask(in context: CGContext) {
        let document = model.state.document
        guard let crop = document.cropRectInPixels else { return }
        let isCropping = model.state.tool == .crop
        let mask = isCropping ? CGColor(gray: 0, alpha: 0.5) : NSColor.windowBackgroundColor.cgColor
        context.addRect(document.imageBoundsInPixels)
        context.addRect(crop)
        context.setFillColor(mask)
        context.fillPath(using: .evenOdd)
    }

    private func drawSelection(in context: CGContext) {
        let mapping = model.mapping
        let state = model.state
        if state.tool == .crop {
            let frame = mapping.canvasRect(fromPixels: state.document.exportRectInPixels)
            context.setStrokeColor(NSColor.white.cgColor)
            context.setLineWidth(1 / mapping.magnification)
            context.stroke(frame)
            drawHandles(at: Handle.positions(for: state.document.exportRectInPixels).values, in: context)
        } else if let selected = state.selectedAnnotation, state.editingTextID == nil {
            drawHandles(at: selected.handlePositions.values, in: context)
        }
    }

    private func drawHandles(at pointsInPixels: some Collection<CGPoint>, in context: CGContext) {
        let side = Self.handleSizeInScreenPoints / model.mapping.magnification
        context.setFillColor(NSColor.white.cgColor)
        context.setStrokeColor(NSColor.controlAccentColor.cgColor)
        context.setLineWidth(1 / model.mapping.magnification)
        for point in pointsInPixels {
            let center = model.mapping.canvasPoint(fromPixel: point)
            let rect = CGRect(x: center.x - side / 2, y: center.y - side / 2, width: side, height: side)
            context.fill(rect)
            context.stroke(rect)
        }
    }
}
