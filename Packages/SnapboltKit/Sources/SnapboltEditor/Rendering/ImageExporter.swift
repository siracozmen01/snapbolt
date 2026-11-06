import CoreGraphics

/// Renders the final image at full resolution, cropped to the document's export rect.
struct ImageExporter: DocumentExporting {
    let renderer: AnnotationRenderer

    init(renderer: AnnotationRenderer) {
        self.renderer = renderer
    }

    func export(_ document: AnnotationDocument) throws(EditorError) -> CGImage {
        let rect = document.exportRectInPixels.integral
        guard
            let context = CGContext(
                data: nil, width: Int(rect.width), height: Int(rect.height), bitsPerComponent: 8, bytesPerRow: 0,
                space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw .exportFailed }
        // Flip to y-down image pixels, then move the crop's origin to the context's origin.
        context.translateBy(x: 0, y: rect.height)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: -rect.minX, y: -rect.minY)
        renderer.drawImage(in: context)
        renderer.draw(document.annotations, in: context)
        guard let image = context.makeImage() else { throw .exportFailed }
        return image
    }

    /// The capture's own RGB colour space, so Display P3 captures keep their colours; sRGB otherwise.
    private var colorSpace: CGColorSpace {
        if let space = renderer.image.colorSpace, space.model == .rgb, space.supportsOutput {
            return space
        }
        return CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    }
}
