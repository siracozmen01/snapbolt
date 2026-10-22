import CoreGraphics
import Testing

@testable import SnapboltEditor

@Suite("Rect resizing")
struct RectResizingTests {
    static let rect = CGRect(x: 10, y: 10, width: 100, height: 50)

    @Test(
        "Dragging each handle to the origin moves only that handle's edges",
        arguments: [
            (Handle.topLeft, CGRect(x: 0, y: 0, width: 110, height: 60)),
            (.top, CGRect(x: 10, y: 0, width: 100, height: 60)),
            (.topRight, CGRect(x: 0, y: 0, width: 10, height: 60)),
            (.right, CGRect(x: 0, y: 10, width: 10, height: 50)),
            (.bottomRight, CGRect(x: 0, y: 0, width: 10, height: 10)),
            (.bottom, CGRect(x: 10, y: 0, width: 100, height: 10)),
            (.bottomLeft, CGRect(x: 0, y: 0, width: 110, height: 10)),
            (.left, CGRect(x: 0, y: 10, width: 110, height: 50)),
        ])
    func dragsEachHandle(handle: Handle, expected: CGRect) {
        #expect(RectResizing.resized(Self.rect, dragging: handle, to: .zero) == expected)
    }

    @Test("Dragging past the opposite edge flips the rect instead of making it negative")
    func flipsWhenDraggedPastOppositeEdge() {
        let resized = RectResizing.resized(Self.rect, dragging: .right, to: CGPoint(x: 0, y: 30))

        #expect(resized == CGRect(x: 0, y: 10, width: 10, height: 50))
        #expect(resized.width > 0)
    }

    @Test("Shift makes a square in the drag direction")
    func squaresWithShift() {
        let square = RectResizing.rect(from: .zero, to: CGPoint(x: 30, y: -10), square: true)

        #expect(square == CGRect(x: 0, y: -30, width: 30, height: 30))
    }

    @Test("Without shift the rect spans both points")
    func spansBothPoints() {
        #expect(
            RectResizing.rect(from: CGPoint(x: 50, y: 40), to: CGPoint(x: 10, y: 60), square: false)
                == CGRect(x: 10, y: 40, width: 40, height: 20))
    }

    @Test("Handle positions sit on the rect's corners and edge midpoints")
    func handlePositions() {
        let positions = Handle.positions(for: Self.rect)

        #expect(positions.count == 8)
        #expect(positions[.topLeft] == CGPoint(x: 10, y: 10))
        #expect(positions[.right] == CGPoint(x: 110, y: 35))
        #expect(positions[.bottom] == CGPoint(x: 60, y: 60))
    }
}
