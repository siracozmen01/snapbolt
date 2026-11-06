import CoreGraphics
import Testing

@testable import SnapboltEditor

@Suite("Editor window layout")
struct EditorWindowLayoutTests {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    @Test("A small image opens at 100% with the toolbar above it")
    func smallImageOpensAtActualSize() {
        let layout = EditorWindowLayout.initial(
            imageSizeInPoints: CGSize(width: 800, height: 600), visibleFrame: screen)

        #expect(layout.magnification == 1)
        #expect(layout.contentSize == CGSize(width: 800, height: 652))
    }

    @Test("A large image is fitted into 85% of the screen")
    func largeImageIsFitted() {
        let image = CGSize(width: 3000, height: 2000)

        let layout = EditorWindowLayout.initial(imageSizeInPoints: image, visibleFrame: screen)

        #expect(layout.contentSize == CGSize(width: 1632, height: 918))
        #expect(layout.magnification == ZoomLevels.fitting(image, in: CGSize(width: 1632, height: 866)))
    }

    @Test("A tiny image still gets a window wide enough for the toolbar")
    func tinyImageKeepsToolbarWidth() {
        let layout = EditorWindowLayout.initial(imageSizeInPoints: CGSize(width: 50, height: 40), visibleFrame: screen)

        #expect(layout.contentSize.width == EditorWindowLayout.minimumContentWidth)
        #expect(layout.magnification == 1)
    }
}
