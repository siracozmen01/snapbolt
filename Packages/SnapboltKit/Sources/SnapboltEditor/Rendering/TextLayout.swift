import CoreGraphics
import CoreText
import Foundation

/// Lays out multi-line text in the system font; the single source of text sizes for drawing, hit testing
/// and the editing field.
struct TextLayout {
    let string: String
    let fontSizeInPixels: CGFloat
    /// The size of all lines, the widest line's width by the lines' total height.
    let sizeInPixels: CGSize

    private let lines: [String]
    private let ascent: CGFloat
    private let lineHeight: CGFloat

    init(string: String, fontSizeInPixels: CGFloat) {
        self.string = string
        self.fontSizeInPixels = fontSizeInPixels
        let font = Self.font(size: fontSizeInPixels)
        lines = string.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        ascent = CTFontGetAscent(font)
        lineHeight = (ascent + CTFontGetDescent(font) + CTFontGetLeading(font)).rounded(.up)
        let width = lines.map { Self.width(of: $0, font: font) }.max() ?? 0
        sizeInPixels = CGSize(width: width.rounded(.up), height: lineHeight * CGFloat(lines.count))
    }

    /// Draws the text with its top-left corner at `originInPixels` into a y-down context.
    func draw(in context: CGContext, at originInPixels: CGPoint, color: RGBAColor) {
        let font = Self.font(size: fontSizeInPixels)
        context.saveGState()
        defer { context.restoreGState() }
        // The context is y-down; Core Text draws y-up glyphs, so flip the text matrix only.
        context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        for (index, line) in lines.enumerated() {
            let attributed = Self.attributed(line, font: font, color: color.cgColor)
            context.textPosition = CGPoint(
                x: originInPixels.x, y: originInPixels.y + ascent + lineHeight * CGFloat(index))
            CTLineDraw(CTLineCreateWithAttributedString(attributed), context)
        }
    }

    private static func font(size: CGFloat) -> CTFont {
        CTFontCreateUIFontForLanguage(.system, size, nil) ?? CTFontCreateWithName("Helvetica" as CFString, size, nil)
    }

    private static func width(of line: String, font: CTFont) -> CGFloat {
        let attributed = attributed(line, font: font, color: CGColor(gray: 0, alpha: 1))
        return CGFloat(CTLineGetTypographicBounds(CTLineCreateWithAttributedString(attributed), nil, nil, nil))
    }

    private static func attributed(_ line: String, font: CTFont, color: CGColor) -> CFAttributedString {
        NSAttributedString(
            string: line,
            attributes: [
                NSAttributedString.Key(kCTFontAttributeName as String): font,
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
            ])
    }
}
