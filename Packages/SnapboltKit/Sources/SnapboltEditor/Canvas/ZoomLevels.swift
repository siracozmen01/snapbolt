import CoreGraphics

/// The canvas's zoom steps and limits; 1 shows one image point per screen point.
enum ZoomLevels {
    static let steps: [CGFloat] = [0.1, 0.25, 0.5, 0.75, 1, 1.5, 2, 3, 4, 6, 8]
    static let minimum: CGFloat = 0.1
    static let maximum: CGFloat = 8
    /// Above this magnification the image is drawn with sharp pixels for precise cropping.
    static let nearestNeighbourAbove: CGFloat = 2

    private static let epsilon: CGFloat = 0.0001

    static func zoomedIn(from magnification: CGFloat) -> CGFloat {
        steps.first { $0 > magnification + epsilon } ?? maximum
    }

    static func zoomedOut(from magnification: CGFloat) -> CGFloat {
        steps.last { $0 < magnification - epsilon } ?? minimum
    }

    /// The magnification that fits `contentSizeInPoints` into `availableSize`, within the limits.
    static func fitting(_ contentSizeInPoints: CGSize, in availableSize: CGSize) -> CGFloat {
        guard contentSizeInPoints.width > 0, contentSizeInPoints.height > 0 else { return 1 }
        let fit = min(
            availableSize.width / contentSizeInPoints.width, availableSize.height / contentSizeInPoints.height)
        return min(max(fit, minimum), maximum)
    }
}
