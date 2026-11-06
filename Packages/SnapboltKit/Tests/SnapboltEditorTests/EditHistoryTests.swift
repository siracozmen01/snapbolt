import CoreGraphics
import Testing

@testable import SnapboltEditor

@Suite("Edit history")
struct EditHistoryTests {
    func document(cropWidth: CGFloat) -> AnnotationDocument {
        var document = AnnotationDocument(imageSizeInPixels: CGSize(width: 500, height: 500))
        document.cropRectInPixels = CGRect(x: 0, y: 0, width: cropWidth, height: 10)
        return document
    }

    @Test("Undoes and redoes")
    func undoesAndRedoes() {
        var history = EditHistory()
        history.record(document(cropWidth: 1))

        let undone = history.undo(from: document(cropWidth: 2))
        let redone = history.redo(from: document(cropWidth: 1))

        #expect(undone == document(cropWidth: 1))
        #expect(redone == document(cropWidth: 2))
    }

    @Test("A new step clears redo")
    func newStepClearsRedo() {
        var history = EditHistory()
        history.record(document(cropWidth: 1))
        _ = history.undo(from: document(cropWidth: 2))

        history.record(document(cropWidth: 1))

        #expect(!history.canRedo)
        #expect(history.canUndo)
    }

    @Test("Keeps at most one hundred steps")
    func keepsAtMostOneHundredSteps() {
        var history = EditHistory()
        for width in 1...101 {
            history.record(document(cropWidth: CGFloat(width)))
        }
        var current = document(cropWidth: 102)
        var undos = 0

        while let previous = history.undo(from: current) {
            current = previous
            undos += 1
        }

        #expect(undos == 100)
        #expect(current == document(cropWidth: 2))
    }
}
