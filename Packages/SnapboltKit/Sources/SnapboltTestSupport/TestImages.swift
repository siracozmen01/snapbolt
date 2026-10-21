import CoreGraphics

extension CGImage {
    /// Returns an opaque mid-grey image of the given pixel size, for tests that need a real `CGImage`.
    public static func solid(width: Int, height: Int) -> CGImage {
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            preconditionFailure("A bitmap context with positive dimensions can always be created")
        }
        context.setFillColor(gray: 0.5, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else {
            preconditionFailure("A bitmap context always produces an image")
        }
        return image
    }
}
