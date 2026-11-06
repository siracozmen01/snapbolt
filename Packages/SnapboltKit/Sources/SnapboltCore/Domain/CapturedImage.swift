import CoreGraphics

/// A cropped capture and the scale of the display it came from.
public struct CapturedImage: Sendable {
    /// The captured pixels.
    public let image: CGImage
    /// Pixels per point of the source display.
    public let scale: CGFloat

    /// Creates a captured image.
    public init(image: CGImage, scale: CGFloat) {
        self.image = image
        self.scale = scale
    }
}
