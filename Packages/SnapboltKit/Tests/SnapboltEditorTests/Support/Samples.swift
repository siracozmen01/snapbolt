import CoreGraphics

@testable import SnapboltEditor

/// Shapes with readable defaults for tests.
enum Samples {
    static func arrow(from start: CGPoint, to end: CGPoint, width: CGFloat = 4) -> ArrowAnnotation {
        ArrowAnnotation(startInPixels: start, endInPixels: end, color: .defaultRed, lineWidthInPixels: width)
    }

    static func rectangle(
        _ rect: CGRect, width: CGFloat = 4, filled: Bool = false, color: RGBAColor = .defaultRed
    ) -> RectangleAnnotation {
        RectangleAnnotation(rectInPixels: rect, color: color, lineWidthInPixels: width, isFilled: filled)
    }

    static func text(
        _ string: String, at origin: CGPoint = .zero, fontSize: CGFloat = 40, background: Bool = false,
        color: RGBAColor = .defaultRed
    ) -> TextAnnotation {
        TextAnnotation(
            string: string, originInPixels: origin, color: color, fontSizeInPixels: fontSize,
            hasBackground: background)
    }

    static func redaction(_ rect: CGRect, mode: RedactionMode = .pixelate, strength: Double = 40)
        -> RedactionAnnotation
    {
        RedactionAnnotation(rectInPixels: rect, mode: mode, strength: strength)
    }
}
