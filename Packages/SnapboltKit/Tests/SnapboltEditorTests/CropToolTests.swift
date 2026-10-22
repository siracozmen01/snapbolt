import CoreGraphics
import Testing

@testable import SnapboltEditor

@Suite("Crop tool")
struct CropToolTests {
    @Test("Dragging without a crop draws a new frame")
    func drawsNewFrame() {
        var tool = CropTool()

        let state = tool.drag(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 60, y: 40), in: .empty())

        #expect(state.document.cropRectInPixels == CGRect(x: 10, y: 10, width: 50, height: 30))
    }

    @Test("Keeps the frame inside the image")
    func clampsToImage() {
        var tool = CropTool()

        let state = tool.drag(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 500, y: -20), in: .empty())

        #expect(state.document.cropRectInPixels == CGRect(x: 10, y: 0, width: 190, height: 10))
    }

    @Test("Rounds the frame to whole pixels")
    func roundsToWholePixels() throws {
        var tool = CropTool()

        let state = tool.drag(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 60.6, y: 40.2), in: .empty())

        let crop = try #require(state.document.cropRectInPixels)
        #expect(crop == crop.integral)
    }

    @Test("A frame covering the whole image means no crop")
    func fullImageMeansNoCrop() {
        var start = EditorState.empty()
        start.document.cropRectInPixels = CGRect(x: 0, y: 0, width: 200, height: 90)
        var tool = CropTool()

        let state = tool.drag(from: CGPoint(x: 100, y: 90), to: CGPoint(x: 100, y: 100), in: start)

        #expect(state.document.cropRectInPixels == nil)
    }

    @Test("Moving the frame keeps it inside the image")
    func movesFrameInsideImage() {
        var start = EditorState.empty()
        start.document.cropRectInPixels = CGRect(x: 10, y: 10, width: 50, height: 30)
        var tool = CropTool()

        let state = tool.drag(from: CGPoint(x: 30, y: 20), to: CGPoint(x: -70, y: 20), in: start)

        #expect(state.document.cropRectInPixels == CGRect(x: 0, y: 10, width: 50, height: 30))
    }

    @Test("A click outside an existing frame keeps it")
    func clickOutsideKeepsFrame() {
        var start = EditorState.empty()
        start.document.cropRectInPixels = CGRect(x: 10, y: 10, width: 50, height: 30)
        var tool = CropTool()

        let state = tool.drag(from: CGPoint(x: 150, y: 80), to: CGPoint(x: 151, y: 80), in: start)

        #expect(state.document.cropRectInPixels == CGRect(x: 10, y: 10, width: 50, height: 30))
    }
}
