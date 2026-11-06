import CoreGraphics
import Testing

@testable import SnapboltEditor

@Suite("Text annotation")
struct TextAnnotationTests {
    @Test("A background adds a quarter of the font size of padding on every side")
    func boundsIncludePadding() {
        let text = Samples.text("Hello", at: CGPoint(x: 5, y: 7), fontSize: 40, background: true)
        let layout = TextLayout(string: "Hello", fontSizeInPixels: 40).sizeInPixels

        #expect(
            text.boundsInPixels
                == CGRect(x: 5, y: 7, width: layout.width + 20, height: layout.height + 20))
    }

    @Test("Dragging a corner scales the font with the opposite corner fixed")
    func cornerResizeScalesFont() {
        let text = Samples.text("Hello", at: CGPoint(x: 10, y: 20), fontSize: 40)
        let bounds = text.boundsInPixels

        let resized = text.resized(
            dragging: .bottomRight, to: CGPoint(x: bounds.maxX, y: bounds.minY + 2 * bounds.height))

        #expect(abs(resized.fontSizeInPixels - 80) < 0.001)
        #expect(resized.originInPixels == CGPoint(x: 10, y: 20))
        #expect(Set(text.handlePositions.keys) == [.topLeft, .topRight, .bottomRight, .bottomLeft])
    }

    @Test("Each line adds height; empty text is one line tall")
    func multiLineIsTaller() {
        let one = TextLayout(string: "a", fontSizeInPixels: 20).sizeInPixels
        let two = TextLayout(string: "a\nb", fontSizeInPixels: 20).sizeInPixels
        let empty = TextLayout(string: "", fontSizeInPixels: 20).sizeInPixels

        #expect(two.height > one.height)
        #expect(empty.height == one.height)
    }
}
