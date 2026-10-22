import CoreGraphics
import Foundation
import SnapboltTestSupport

extension CGImage {
    /// Top half red, bottom half blue: shows whether something is upside down.
    static func split(width: Int, height: Int) -> CGImage {
        pattern(width: width, height: height) { _, row in row < height / 2 ? .pureRed : .pureBlue }
    }

    /// One-pixel black and white columns: pixelation turns them into uniform blocks.
    static func stripes(width: Int, height: Int) -> CGImage {
        pattern(width: width, height: height) { column, _ in column.isMultiple(of: 2) ? .pureBlack : .pureWhite }
    }

    /// An opaque image whose pixel at (column, row), row 0 at the top, has the colour `color` returns.
    static func pattern(
        width: Int, height: Int, color: (Int, Int) -> PixelColor,
        space: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    ) -> CGImage {
        var bytes = [UInt8]()
        bytes.reserveCapacity(width * height * 4)
        for row in 0..<height {
            for column in 0..<width {
                let pixel = color(column, row)
                bytes += [pixel.red, pixel.green, pixel.blue, 255]
            }
        }
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        return CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
            space: space, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    }
}

extension PixelColor {
    static let pureRed = PixelColor(red: 255, green: 0, blue: 0, alpha: 255)
    static let pureGreen = PixelColor(red: 0, green: 255, blue: 0, alpha: 255)
    static let pureBlue = PixelColor(red: 0, green: 0, blue: 255, alpha: 255)
    static let pureBlack = PixelColor(red: 0, green: 0, blue: 0, alpha: 255)
    static let pureWhite = PixelColor(red: 255, green: 255, blue: 255, alpha: 255)
}
