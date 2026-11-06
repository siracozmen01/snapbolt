import CoreGraphics
import CoreImage
import Foundation
import SnapboltTestSupport
import Testing

@testable import SnapboltEditor

@Suite("Image exporter")
struct ImageExporterTests {
    static let green = RGBAColor(red: 0, green: 1, blue: 0, alpha: 1)

    func export(_ document: AnnotationDocument, on image: CGImage, scale: CGFloat = 1) throws -> CGImage {
        let redactions = RedactionRenderer(source: image, scale: scale, context: CIContext())
        return try ImageExporter(renderer: AnnotationRenderer(image: image, redactions: redactions)).export(document)
    }

    func document(_ image: CGImage, _ kinds: [Annotation.Kind]) -> AnnotationDocument {
        var document = AnnotationDocument(imageSizeInPixels: CGSize(width: image.width, height: image.height))
        for kind in kinds {
            document.upsert(Annotation(id: UUID(), kind: kind))
        }
        return document
    }

    func isRed(_ pixel: PixelColor) -> Bool { pixel.red > 200 && pixel.green < 100 && pixel.blue < 100 }
    func isGrey(_ pixel: PixelColor) -> Bool { (100...160).contains(pixel.red) && (100...160).contains(pixel.green) }
    func isGreen(_ pixel: PixelColor) -> Bool { pixel.green > 200 && pixel.red < 100 }

    @Test("Without annotations the image is exported unchanged and upright")
    func exportsImageUnchangedWithoutAnnotations() throws {
        let image = CGImage.split(width: 40, height: 40)

        let output = try export(document(image, []), on: image)

        #expect(output.pixel(atX: 0, y: 0) == .pureRed)
        #expect(output.pixel(atX: 0, y: 39) == .pureBlue)
    }

    @Test("Shapes land where the document puts them, top-left origin")
    func exportKeepsOrientation() throws {
        let image = CGImage.solid(width: 40, height: 40)
        let rect = Samples.rectangle(CGRect(x: 0, y: 0, width: 10, height: 10), filled: true)

        let output = try export(document(image, [.rectangle(rect)]), on: image)

        #expect(isRed(output.pixel(atX: 5, y: 5)))
        #expect(isGrey(output.pixel(atX: 5, y: 34)))
    }

    @Test("Exports the crop's size with shapes offset by its origin")
    func exportsCropSizeAndOffset() throws {
        let image = CGImage.solid(width: 40, height: 40)
        var cropped = document(
            image, [.rectangle(Samples.rectangle(CGRect(x: 10, y: 20, width: 5, height: 5), filled: true))])
        cropped.cropRectInPixels = CGRect(x: 10, y: 20, width: 30, height: 15)

        let output = try export(cropped, on: image)

        #expect(output.width == 30)
        #expect(output.height == 15)
        #expect(isRed(output.pixel(atX: 2, y: 2)))
        #expect(isGrey(output.pixel(atX: 8, y: 8)))
    }

    @Test("A 4 pt line on a scale-2 capture is 8 px wide, centred on the edge")
    func exportsStylesInPixelsAtScaleTwo() throws {
        let image = CGImage.solid(width: 100, height: 100)
        var style = ToolStyle.standard
        style.lineWidthInPoints = 4
        let rect = Samples.rectangle(CGRect(x: 10, y: 10, width: 80, height: 80)).restyled(style, scale: 2)

        let output = try export(document(image, [.rectangle(rect)]), on: image, scale: 2)

        #expect(isRed(output.pixel(atX: 13, y: 50)))
        #expect(isGrey(output.pixel(atX: 15, y: 50)))
    }

    @Test("A redaction hides the shapes below it")
    func redactionHidesShapesBelowIt() throws {
        let image = CGImage.solid(width: 40, height: 40)
        let area = CGRect(x: 0, y: 0, width: 20, height: 20)
        let kinds: [Annotation.Kind] = [
            .rectangle(Samples.rectangle(area, filled: true, color: Self.green)), .redaction(Samples.redaction(area)),
        ]

        let output = try export(document(image, kinds), on: image)

        #expect(isGrey(output.pixel(atX: 10, y: 10)))
    }

    @Test("Shapes above a redaction stay visible")
    func shapesAboveRedactionStayVisible() throws {
        let image = CGImage.solid(width: 40, height: 40)
        let area = CGRect(x: 0, y: 0, width: 20, height: 20)
        let kinds: [Annotation.Kind] = [
            .redaction(Samples.redaction(area)), .rectangle(Samples.rectangle(area, filled: true, color: Self.green)),
        ]

        let output = try export(document(image, kinds), on: image)

        #expect(isGreen(output.pixel(atX: 10, y: 10)))
    }

    @Test("Light text gets a dark background box")
    func textBackgroundUsesContrast() throws {
        let image = CGImage.solid(width: 100, height: 100)
        let white = RGBAColor(red: 1, green: 1, blue: 1, alpha: 1)
        let text = Samples.text("Hi", at: CGPoint(x: 5, y: 5), fontSize: 20, background: true, color: white)

        let output = try export(document(image, [.text(text)]), on: image)

        let pixel = output.pixel(atX: 7, y: Int(text.boundsInPixels.midY))
        #expect(pixel.red < 100 && pixel.green < 100 && pixel.blue < 100, "\(pixel)")
    }

    @Test("Keeps the capture's colour space")
    func preservesColourSpace() throws {
        let displayP3 = try #require(CGColorSpace(name: CGColorSpace.displayP3))
        let image = CGImage.pattern(width: 10, height: 10, color: { _, _ in .pureRed }, space: displayP3)

        let output = try export(document(image, []), on: image)

        #expect(output.colorSpace?.name == CGColorSpace.displayP3)
    }
}
