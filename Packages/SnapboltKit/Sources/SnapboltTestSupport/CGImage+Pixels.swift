import CoreGraphics

extension CGImage {
    /// Returns the pixel at column `x` and row `y`, where row 0 is the top of the image, in sRGB.
    public func pixel(atX x: Int, y: Int) -> PixelColor {
        var bytes = [UInt8](repeating: 0, count: 4)
        guard
            let space = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: &bytes, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else {
            preconditionFailure("A 1×1 sRGB bitmap context can always be created")
        }
        // Core Graphics is y-up: shift the image so the requested pixel covers the context's only pixel.
        context.draw(self, in: CGRect(x: -x, y: y - height + 1, width: width, height: height))
        return PixelColor(red: bytes[0], green: bytes[1], blue: bytes[2], alpha: bytes[3])
    }
}
