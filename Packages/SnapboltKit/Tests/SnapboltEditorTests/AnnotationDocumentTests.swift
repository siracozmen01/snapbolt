import CoreGraphics
import Foundation
import Testing

@testable import SnapboltEditor

@Suite("Annotation document")
struct AnnotationDocumentTests {
    let first = Annotation(id: UUID(), kind: .rectangle(Samples.rectangle(CGRect(x: 0, y: 0, width: 5, height: 5))))
    let second = Annotation(id: UUID(), kind: .redaction(Samples.redaction(CGRect(x: 1, y: 1, width: 5, height: 5))))

    @Test("Upserting an existing shape keeps its place in the z-order; a new one goes on top")
    func upsertKeepsZOrder() {
        var document = AnnotationDocument(imageSizeInPixels: CGSize(width: 100, height: 100))
        document.upsert(first)
        document.upsert(second)

        document.upsert(first.moved(by: CGVector(dx: 3, dy: 3)))

        #expect(document.annotations.map(\.id) == [first.id, second.id])
        #expect(document.annotation(withID: first.id)?.boundsInPixels.minX == first.boundsInPixels.minX + 3)
    }

    @Test("Removes a shape by id")
    func removesByID() {
        var document = AnnotationDocument(imageSizeInPixels: CGSize(width: 100, height: 100))
        document.upsert(first)

        document.remove(id: first.id)

        #expect(document.annotations.isEmpty)
    }

    @Test("Exports the whole image unless cropped")
    func exportRectDefaultsToImage() {
        var document = AnnotationDocument(imageSizeInPixels: CGSize(width: 200, height: 100))

        #expect(document.exportRectInPixels == CGRect(x: 0, y: 0, width: 200, height: 100))
        document.cropRectInPixels = CGRect(x: 10, y: 10, width: 50, height: 30)
        #expect(document.exportRectInPixels == CGRect(x: 10, y: 10, width: 50, height: 30))
    }
}
