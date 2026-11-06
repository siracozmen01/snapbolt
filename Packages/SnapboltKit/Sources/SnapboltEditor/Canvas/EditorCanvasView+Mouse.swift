import AppKit

extension EditorCanvasView {
    override func mouseDown(with event: NSEvent) {
        if textField != nil {
            // A click outside the open text field only commits it.
            commitTextEditing()
            return
        }
        window?.makeFirstResponder(self)
        model.pointerDown(
            atCanvas: convert(event.locationInWindow, from: nil), isShiftDown: event.modifierFlags.contains(.shift),
            clickCount: event.clickCount)
    }

    override func mouseDragged(with event: NSEvent) {
        model.pointerDragged(
            toCanvas: convert(event.locationInWindow, from: nil), isShiftDown: event.modifierFlags.contains(.shift))
    }

    override func mouseUp(with event: NSEvent) {
        model.pointerUp(
            atCanvas: convert(event.locationInWindow, from: nil), isShiftDown: event.modifierFlags.contains(.shift))
    }

    override func resetCursorRects() {
        addCursorRect(visibleRect, cursor: model.state.tool == .select ? .arrow : .crosshair)
    }
}
