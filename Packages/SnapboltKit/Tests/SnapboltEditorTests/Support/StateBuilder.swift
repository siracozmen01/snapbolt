import CoreGraphics
import Foundation

@testable import SnapboltEditor

extension EditorState {
    /// An empty state for a `width × height` px image, optionally with shapes already on it.
    static func empty(width: CGFloat = 200, height: CGFloat = 100, with kinds: [Annotation.Kind] = []) -> EditorState {
        var state = EditorState(document: AnnotationDocument(imageSizeInPixels: CGSize(width: width, height: height)))
        for kind in kinds {
            state.document.upsert(Annotation(id: UUID(), kind: kind))
        }
        return state
    }
}

extension ToolInteraction {
    /// Runs a press at `from`, one move and a release at `to`.
    mutating func drag(
        from: CGPoint, to: CGPoint, in state: EditorState, shift: Bool = false, scale: CGFloat = 1
    ) -> EditorState {
        var state = began(PointerInput(pointInPixels: from, isShiftDown: shift, scale: scale), in: state)
        state = moved(PointerInput(pointInPixels: to, isShiftDown: shift, scale: scale), in: state)
        return ended(PointerInput(pointInPixels: to, isShiftDown: shift, scale: scale), in: state)
    }
}
