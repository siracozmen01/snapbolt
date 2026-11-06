import CoreGraphics
import Foundation
import Testing

@testable import SnapboltEditor

@Suite("Annotation")
struct AnnotationTests {
    static let kinds: [Annotation.Kind] = [
        .arrow(Samples.arrow(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 60, y: 40))),
        .rectangle(Samples.rectangle(CGRect(x: 10, y: 10, width: 50, height: 30))),
        .text(Samples.text("Hi", at: CGPoint(x: 10, y: 10))),
        .redaction(Samples.redaction(CGRect(x: 10, y: 10, width: 50, height: 30))),
    ]

    @Test("Moving shifts the bounds of every kind", arguments: kinds)
    func movesEveryKind(_ kind: Annotation.Kind) {
        let annotation = Annotation(id: UUID(), kind: kind)

        let moved = annotation.moved(by: CGVector(dx: 5, dy: -3))

        #expect(moved.boundsInPixels == annotation.boundsInPixels.offsetBy(dx: 5, dy: -3))
        #expect(moved.id == annotation.id)
    }

    @Test("Each kind belongs to its tool")
    func mapsKindsToTools() {
        #expect(Self.kinds.map { Annotation(id: UUID(), kind: $0).tool } == [.arrow, .rectangle, .text, .redaction])
    }
}
