import CoreGraphics
import Foundation
import Testing

@testable import SnapboltEditor

@Suite("Editor state")
struct EditorStateTests {
    @Test("Falls back to the standard style for tools without a saved one")
    func fallsBackToStandardStyle() {
        let state = EditorState(document: AnnotationDocument(imageSizeInPixels: CGSize(width: 10, height: 10)))

        #expect(state.style(for: .text) == .standard)
        #expect(state.tool == .arrow)
    }

    @Test("Finds the selected annotation")
    func findsSelection() {
        let annotation = Annotation(
            id: UUID(), kind: .redaction(Samples.redaction(CGRect(x: 0, y: 0, width: 5, height: 5))))
        var state = EditorState(document: AnnotationDocument(imageSizeInPixels: CGSize(width: 10, height: 10)))
        state.document.upsert(annotation)

        state.selectedID = annotation.id

        #expect(state.selectedAnnotation == annotation)
    }
}
