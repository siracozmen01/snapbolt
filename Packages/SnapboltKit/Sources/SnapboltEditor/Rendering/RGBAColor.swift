import CoreGraphics
import Foundation

/// An sRGB colour with opacity, as a comparable value (`CGColor` is neither `Equatable` by value nor `Codable`).
struct RGBAColor: Codable, Hashable, Sendable {
    /// The system red (#FF3B30), the default for every tool.
    static let defaultRed = RGBAColor(red: 1, green: 59 / 255, blue: 48 / 255, alpha: 1)

    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Converts `cgColor` to sRGB; `nil` when it cannot be converted (for example a pattern colour).
    init?(cgColor: CGColor) {
        guard
            let space = CGColorSpace(name: CGColorSpace.sRGB),
            let converted = cgColor.converted(to: space, intent: .defaultIntent, options: nil),
            let components = converted.components, components.count == 4
        else { return nil }
        self.init(
            red: Double(components[0]), green: Double(components[1]), blue: Double(components[2]),
            alpha: Double(components[3]))
    }

    var cgColor: CGColor {
        CGColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }

    /// WCAG relative luminance, 0 for black to 1 for white.
    var relativeLuminance: Double {
        0.2126 * Self.linearized(red) + 0.7152 * Self.linearized(green) + 0.0722 * Self.linearized(blue)
    }

    /// Whether dark text or backgrounds contrast better with this colour.
    var isLight: Bool { relativeLuminance > 0.5 }

    private static func linearized(_ component: Double) -> Double {
        component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
    }
}
