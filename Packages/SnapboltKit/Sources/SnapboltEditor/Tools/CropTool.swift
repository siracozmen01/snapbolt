import CoreGraphics
import SnapboltCore

/// Edits the crop frame: resize by its handles, move it from inside, or draw a new one.
struct CropTool: ToolInteraction {
    private enum Gesture {
        case idle
        case resizing(Handle, frame: CGRect)
        case moving(from: CGPoint, frame: CGRect)
        case drawing(from: CGPoint)
    }

    private var gesture = Gesture.idle
    private var cropBeforeGesture: CGRect?

    /// `rectInPixels` with whole-pixel edges, inside the image and at least 1 × 1 px.
    static func clamped(_ rectInPixels: CGRect, to imageSizeInPixels: CGSize) -> CGRect {
        let rect = rectInPixels.standardized
        let minX = min(max(rect.minX.rounded(), 0), imageSizeInPixels.width - 1)
        let minY = min(max(rect.minY.rounded(), 0), imageSizeInPixels.height - 1)
        let maxX = min(max(rect.maxX.rounded(), minX + 1), imageSizeInPixels.width)
        let maxY = min(max(rect.maxY.rounded(), minY + 1), imageSizeInPixels.height)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    mutating func began(_ input: PointerInput, in state: EditorState) -> EditorState {
        let document = state.document
        let frame = document.exportRectInPixels
        cropBeforeGesture = document.cropRectInPixels
        if let handle = Self.handle(of: frame, near: input.pointInPixels, within: input.toleranceInPixels) {
            gesture = .resizing(handle, frame: frame)
        } else if document.cropRectInPixels != nil, frame.contains(input.pointInPixels) {
            gesture = .moving(from: input.pointInPixels, frame: frame)
        } else {
            // Without a crop the frame is the whole image, so a drag inside it starts a new frame.
            gesture = .drawing(from: input.pointInPixels)
        }
        return state
    }

    mutating func moved(_ input: PointerInput, in state: EditorState) -> EditorState {
        guard let frame = frame(for: input, imageSize: state.document.imageSizeInPixels) else { return state }
        var state = state
        let clamped = Self.clamped(frame, to: state.document.imageSizeInPixels)
        state.document.cropRectInPixels = clamped == state.document.imageBoundsInPixels ? nil : clamped
        return state
    }

    mutating func ended(_ input: PointerInput, in state: EditorState) -> EditorState {
        var state = moved(input, in: state)
        if case .drawing(let start) = gesture, Self.isTiny(from: start, to: input) {
            state.document.cropRectInPixels = cropBeforeGesture
        }
        gesture = .idle
        return state
    }

    private func frame(for input: PointerInput, imageSize: CGSize) -> CGRect? {
        let point = input.pointInPixels
        switch gesture {
        case .idle:
            return nil
        case .resizing(let handle, let frame):
            return RectResizing.resized(frame, dragging: handle, to: point)
        case .moving(let from, let frame):
            let x = min(max(frame.minX + point.x - from.x, 0), imageSize.width - frame.width)
            let y = min(max(frame.minY + point.y - from.y, 0), imageSize.height - frame.height)
            return CGRect(origin: CGPoint(x: x, y: y), size: frame.size)
        case .drawing(let start):
            return RectResizing.rect(from: start, to: point, square: input.isShiftDown)
        }
    }

    private static func handle(of frame: CGRect, near point: CGPoint, within tolerance: CGFloat) -> Handle? {
        Handle.positions(for: frame)
            .map { ($0.key, hypot($0.value.x - point.x, $0.value.y - point.y)) }
            .filter { $0.1 <= tolerance }
            .min { $0.1 < $1.1 }?.0
    }

    private static func isTiny(from start: CGPoint, to input: PointerInput) -> Bool {
        let minimum = CanvasMapping(scale: input.scale).pixels(fromPoints: ShapeDrawingTool.minimumDragInPoints)
        return abs(input.pointInPixels.x - start.x) < minimum && abs(input.pointInPixels.y - start.y) < minimum
    }
}
