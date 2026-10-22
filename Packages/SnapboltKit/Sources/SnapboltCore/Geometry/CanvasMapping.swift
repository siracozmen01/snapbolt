import CoreGraphics

/// Converts between image pixels and the editor's canvas points.
///
/// Image pixels have their origin at the top-left of the captured image, y down. Canvas points are the
/// flipped canvas view's coordinates (also y down) before the scroll view's magnification is applied.
public struct CanvasMapping: Equatable, Sendable {
    /// Pixels per point of the captured image.
    public let scale: CGFloat
    /// The scroll view's magnification; 1 shows one image point per screen point.
    public var magnification: CGFloat

    /// Creates a mapping for an image of the given scale.
    public init(scale: CGFloat, magnification: CGFloat = 1) {
        self.scale = scale
        self.magnification = magnification
    }

    /// Converts an image pixel position to canvas points.
    public func canvasPoint(fromPixel point: CGPoint) -> CGPoint {
        CGPoint(x: point.x / scale, y: point.y / scale)
    }

    /// Converts a canvas position to image pixels.
    public func pixelPoint(fromCanvas point: CGPoint) -> CGPoint {
        CGPoint(x: point.x * scale, y: point.y * scale)
    }

    /// Converts a rect in image pixels to canvas points.
    public func canvasRect(fromPixels rect: CGRect) -> CGRect {
        CGRect(x: rect.minX / scale, y: rect.minY / scale, width: rect.width / scale, height: rect.height / scale)
    }

    /// Converts a rect in canvas points to image pixels.
    public func pixelRect(fromCanvas rect: CGRect) -> CGRect {
        CGRect(x: rect.minX * scale, y: rect.minY * scale, width: rect.width * scale, height: rect.height * scale)
    }

    /// Converts a style size in points (as seen at 100% zoom) to image pixels.
    public func pixels(fromPoints length: CGFloat) -> CGFloat {
        length * scale
    }

    /// Converts a length in image pixels to points at 100% zoom.
    public func points(fromPixels length: CGFloat) -> CGFloat {
        length / scale
    }

    /// Converts a length that should look constant on screen (a handle, a hit tolerance) to image pixels.
    public func pixels(fromScreenPoints length: CGFloat) -> CGFloat {
        length / magnification * scale
    }
}
