import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import SnapboltCore
import Synchronization

/// Makes the pixelated or blurred patch for a redaction area. Patches always sample the original capture,
/// never the shapes drawn on it, so each one is cached until its area, mode or strength changes.
final class RedactionRenderer: Sendable {
    /// At most this many patches are kept; dragging an area makes a new patch at every position.
    static let cacheLimit = 32

    private let source: CGImage
    private let scale: CGFloat
    private let context: CIContext
    private let cache = Mutex<[RedactionAnnotation: CGImage]>([:])

    init(source: CGImage, scale: CGFloat, context: CIContext) {
        self.source = source
        self.scale = scale
        self.context = context
    }

    /// The number of cached patches, for tests.
    var cachedPatchCount: Int { cache.withLock { $0.count } }

    /// The side of a pixelate block: (4 + 28 × strength / 100) pt.
    static func blockSizeInPixels(strength: Double, scale: CGFloat) -> CGFloat {
        CanvasMapping(scale: scale).pixels(fromPoints: 4 + 28 * clampedStrength(strength) / 100)
    }

    /// The blur radius: (2 + 23 × strength / 100) pt.
    static func blurRadiusInPixels(strength: Double, scale: CGFloat) -> CGFloat {
        CanvasMapping(scale: scale).pixels(fromPoints: 2 + 23 * clampedStrength(strength) / 100)
    }

    /// The opaque patch covering the redaction's area (clipped to the image), or `nil` if the area is
    /// outside the image or Core Image fails.
    func patch(for redaction: RedactionAnnotation) -> CGImage? {
        if let cached = cache.withLock({ $0[redaction] }) { return cached }
        let bounds = CGRect(x: 0, y: 0, width: source.width, height: source.height)
        let rect = redaction.rectInPixels.integral.intersection(bounds)
        guard !rect.isEmpty else { return nil }
        // Core Image is y-up; the document is y-down.
        let areaInCI = CoordinateConversion.bottomUpRect(fromTopDownRect: rect, imageHeight: bounds.height)
        // Cropping first keeps pixels outside the area out of the patch; clamping keeps its edges opaque.
        let input = CIImage(cgImage: source).cropped(to: areaInCI).clampedToExtent()
        guard
            let output = filtered(input, area: areaInCI, redaction: redaction),
            let patch = context.createCGImage(output, from: areaInCI)
        else { return nil }
        cache.withLock { cache in
            // Starting over is simpler than tracking age, and the areas still on the canvas re-render once.
            if cache.count >= Self.cacheLimit { cache.removeAll(keepingCapacity: true) }
            cache[redaction] = patch
        }
        return patch
    }

    /// The filtered image, or `nil`; never the unfiltered input, which would reveal what the user hid.
    private func filtered(_ input: CIImage, area: CGRect, redaction: RedactionAnnotation) -> CIImage? {
        switch redaction.mode {
        case .pixelate:
            let filter = CIFilter.pixellate()
            filter.inputImage = input
            // Blocks start at the area's top-left corner (Core Image's top is maxY).
            filter.center = CGPoint(x: area.minX, y: area.maxY)
            filter.scale = Float(Self.blockSizeInPixels(strength: redaction.strength, scale: scale))
            return filter.outputImage
        case .blur:
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = input
            filter.radius = Float(Self.blurRadiusInPixels(strength: redaction.strength, scale: scale))
            return filter.outputImage
        }
    }

    private static func clampedStrength(_ strength: Double) -> CGFloat {
        CGFloat(min(max(strength, ToolStyle.strengthRange.lowerBound), ToolStyle.strengthRange.upperBound))
    }
}
