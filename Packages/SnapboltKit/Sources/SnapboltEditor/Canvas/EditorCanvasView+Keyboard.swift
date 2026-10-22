import AppKit

/// Every editor shortcut is handled here, in one place.
extension EditorCanvasView: NSMenuItemValidation {
    private enum KeyCode {
        static let returnKey: UInt16 = 36
        static let keypadEnter: UInt16 = 76
        static let delete: UInt16 = 51
        static let forwardDelete: UInt16 = 117
        static let escape: UInt16 = 53
        static let leftArrow: UInt16 = 123
        static let rightArrow: UInt16 = 124
        static let downArrow: UInt16 = 125
        static let upArrow: UInt16 = 126
    }

    override func keyDown(with event: NSEvent) {
        if !handlePlainKey(event) {
            super.keyDown(with: event)
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers.contains(.command) else { return super.performKeyEquivalent(with: event) }
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
        switch (key, modifiers.contains(.shift)) {
        case (_, _) where [KeyCode.returnKey, KeyCode.keypadEnter].contains(event.keyCode):
            onFinish(.upload)
        case ("c", true):
            onFinish(.clipboard)
        case ("=", _), ("+", _):
            onZoom(.zoomIn)
        case ("-", _):
            onZoom(.zoomOut)
        case ("0", false):
            onZoom(.fit)
        case ("1", false):
            onZoom(.actualSize)
        default:
            return super.performKeyEquivalent(with: event)
        }
        return true
    }

    @objc func undo(_ sender: Any?) {
        model.undo()
    }

    @objc func redo(_ sender: Any?) {
        model.redo()
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(undo(_:)): model.canUndo
        case #selector(redo(_:)): model.canRedo
        default: true
        }
    }

    /// Handles a key without ⌘; returns whether it was an editor shortcut.
    private func handlePlainKey(_ event: NSEvent) -> Bool {
        let step: CGFloat = event.modifierFlags.contains(.shift) ? 10 : 1
        switch event.keyCode {
        case KeyCode.escape: model.cancel()
        case KeyCode.delete, KeyCode.forwardDelete: model.deleteSelection()
        case KeyCode.leftArrow: model.nudgeSelection(by: CGVector(dx: -step, dy: 0))
        case KeyCode.rightArrow: model.nudgeSelection(by: CGVector(dx: step, dy: 0))
        case KeyCode.upArrow: model.nudgeSelection(by: CGVector(dx: 0, dy: -step))
        case KeyCode.downArrow: model.nudgeSelection(by: CGVector(dx: 0, dy: step))
        default: return selectTool(for: event)
        }
        return true
    }

    private func selectTool(for event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection([.command, .control, .option])
        guard modifiers.isEmpty, let key = event.charactersIgnoringModifiers?.lowercased().first,
            let tool = EditorTool(shortcutKey: key)
        else { return false }
        model.selectTool(tool)
        return true
    }
}
