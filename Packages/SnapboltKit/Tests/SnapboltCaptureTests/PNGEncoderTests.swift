import CoreGraphics
import ImageIO
import SnapboltTestSupport
import Testing

@testable import SnapboltCapture

@Suite("PNG encoder")
struct PNGEncoderTests {
    @Test("Encodes a PNG with the right signature, type and size")
    func encodesPNGWithSignatureAndSize() throws {
        let encoded = try PNGEncoder().encodePNG(.solid(width: 7, height: 5))

        #expect(Array(encoded.data.prefix(8)) == [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        #expect(encoded.contentType == "image/png")
        #expect(encoded.fileExtension == "png")
        let source = try #require(CGImageSourceCreateWithData(encoded.data as CFData, nil))
        let decoded = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(decoded.width == 7)
        #expect(decoded.height == 5)
    }
}
