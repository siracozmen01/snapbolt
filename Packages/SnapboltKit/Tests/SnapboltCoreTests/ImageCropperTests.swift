import CoreGraphics
import SnapboltTestSupport
import Testing

@testable import SnapboltCore

@Suite("Image cropper")
struct ImageCropperTests {
    let main = FrozenDisplay(
        id: DisplayID(rawValue: 1),
        image: .solid(width: 3024, height: 1964),
        frameInGlobalPoints: CGRect(x: 0, y: 0, width: 1512, height: 982),
        scale: 2
    )

    var screens: FrozenScreens { FrozenScreens(displays: [main], windows: []) }

    @Test("Crops a region to its exact pixel size")
    func cropsRegionToExactPixelSize() throws {
        let image = try ImageCropper.crop(
            screens, to: .region(main.id, rectInPixels: CGRect(x: 10, y: 20, width: 30, height: 40)))

        #expect(image.width == 30)
        #expect(image.height == 40)
    }

    @Test("Crops a window rect")
    func cropsWindowRect() throws {
        let image = try ImageCropper.crop(
            screens, to: .window(main.id, rectInPixels: CGRect(x: 0, y: 0, width: 800, height: 600)))

        #expect(image.width == 800)
        #expect(image.height == 600)
    }

    @Test("Returns the whole display for a display selection")
    func cropsWholeDisplay() throws {
        let image = try ImageCropper.crop(screens, to: .display(main.id))

        #expect(image.width == 3024)
        #expect(image.height == 1964)
    }

    @Test("Throws for a display that was not captured")
    func throwsForUnknownDisplay() {
        #expect(throws: CaptureError.displayNotFound) {
            try ImageCropper.crop(screens, to: .display(DisplayID(rawValue: 9)))
        }
    }

    @Test("Throws for an empty selection")
    func throwsForEmptySelection() {
        #expect(throws: CaptureError.emptySelection) {
            try ImageCropper.crop(
                screens, to: .region(main.id, rectInPixels: CGRect(x: 10, y: 10, width: 0, height: 5)))
        }
    }

    @Test("Throws for a selection outside the image")
    func throwsForSelectionOutsideImage() {
        #expect(throws: CaptureError.emptySelection) {
            try ImageCropper.crop(
                screens, to: .region(main.id, rectInPixels: CGRect(x: 4000, y: 10, width: 50, height: 50)))
        }
    }
}
