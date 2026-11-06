import CoreGraphics

/// The style a tool draws with. Sizes are in points as seen at 100% zoom; shapes store pixels.
struct ToolStyle: Codable, Equatable, Sendable {
    static let lineWidthRangeInPoints: ClosedRange<CGFloat> = 1...40
    static let fontSizeRangeInPoints: ClosedRange<CGFloat> = 8...200
    static let strengthRange: ClosedRange<Double> = 1...100

    /// The defaults from the spec: red, 4 pt lines, 24 pt text, outline rectangles, pixelate at 40.
    static let standard = ToolStyle(
        color: .defaultRed, lineWidthInPoints: 4, isFilled: false, fontSizeInPoints: 24, hasBackground: false,
        redactionMode: .pixelate, redactionStrength: 40)

    var color: RGBAColor
    var lineWidthInPoints: CGFloat
    var isFilled: Bool
    var fontSizeInPoints: CGFloat
    var hasBackground: Bool
    var redactionMode: RedactionMode
    var redactionStrength: Double

    /// This style with every size and the strength moved into its range.
    func clamped() -> ToolStyle {
        var style = self
        style.lineWidthInPoints = Self.clamp(lineWidthInPoints, to: Self.lineWidthRangeInPoints)
        style.fontSizeInPoints = Self.clamp(fontSizeInPoints, to: Self.fontSizeRangeInPoints)
        style.redactionStrength = Self.clamp(redactionStrength, to: Self.strengthRange)
        return style
    }

    private static func clamp<Value: Comparable>(_ value: Value, to range: ClosedRange<Value>) -> Value {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
