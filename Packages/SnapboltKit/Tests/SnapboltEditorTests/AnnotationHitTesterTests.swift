import CoreGraphics
import Foundation
import Testing

@testable import SnapboltEditor

@Suite("Annotation hit tester")
struct AnnotationHitTesterTests {
    let lower = Annotation(
        id: UUID(), kind: .rectangle(Samples.rectangle(CGRect(x: 0, y: 0, width: 100, height: 100), filled: true)))
    let upper = Annotation(
        id: UUID(), kind: .rectangle(Samples.rectangle(CGRect(x: 50, y: 50, width: 100, height: 100), filled: true)))

    var document: AnnotationDocument {
        var document = AnnotationDocument(imageSizeInPixels: CGSize(width: 300, height: 300))
        document.upsert(lower)
        document.upsert(upper)
        return document
    }

    @Test("Prefers the topmost shape")
    func prefersTopmostShape() {
        let hit = AnnotationHitTester.hit(
            at: CGPoint(x: 75, y: 75), in: document, selectedID: nil, toleranceInPixels: 6)

        #expect(hit == .body(upper.id))
    }

    @Test("Offers handles only for the selected shape")
    func handlesOnlyForSelection() {
        let corner = CGPoint(x: 1, y: 1)

        #expect(
            AnnotationHitTester.hit(at: corner, in: document, selectedID: nil, toleranceInPixels: 6)
                == .body(lower.id))
        #expect(
            AnnotationHitTester.hit(at: corner, in: document, selectedID: lower.id, toleranceInPixels: 6)
                == .handle(lower.id, .topLeft))
    }

    @Test("Misses empty canvas")
    func missesEmptyCanvas() {
        #expect(
            AnnotationHitTester.hit(at: CGPoint(x: 250, y: 20), in: document, selectedID: nil, toleranceInPixels: 6)
                == nil)
    }
}
