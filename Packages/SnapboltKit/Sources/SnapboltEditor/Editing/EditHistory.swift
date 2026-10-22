/// Undo and redo as stacks of whole documents. Documents hold no pixels, so a hundred steps are cheap.
struct EditHistory: Sendable {
    static let limit = 100

    private var undoStack: [AnnotationDocument] = []
    private var redoStack: [AnnotationDocument] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    /// Records the document as it was before a change; clears redo and forgets the oldest step past the limit.
    mutating func record(_ previous: AnnotationDocument) {
        undoStack.append(previous)
        if undoStack.count > Self.limit {
            undoStack.removeFirst(undoStack.count - Self.limit)
        }
        redoStack.removeAll()
    }

    /// The document before the last change, or `nil` when there is nothing to undo.
    mutating func undo(from current: AnnotationDocument) -> AnnotationDocument? {
        guard let previous = undoStack.popLast() else { return nil }
        redoStack.append(current)
        return previous
    }

    /// The document the last undo left, or `nil` when there is nothing to redo.
    mutating func redo(from current: AnnotationDocument) -> AnnotationDocument? {
        guard let next = redoStack.popLast() else { return nil }
        undoStack.append(current)
        return next
    }
}
