// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation

// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.

/// One RGBA pixel, 8 bits per channel, as read by `CGImage.pixel(atX:y:)`.
public struct PixelColor: Equatable, Sendable, CustomStringConvertible {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    public let alpha: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public var description: String { "rgba(\(red), \(green), \(blue), \(alpha))" }
}
