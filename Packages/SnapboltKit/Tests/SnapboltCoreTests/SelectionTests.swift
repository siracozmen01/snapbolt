import CoreGraphics
import Testing

@testable import SnapboltCore

@Suite("Selection")
struct SelectionTests {
    static let display = DisplayID(rawValue: 7)

    @Test(
        "Exposes the display it was made on",
        arguments: [
            Selection.region(display, rectInPixels: CGRect(x: 1, y: 2, width: 3, height: 4)),
            Selection.window(display, rectInPixels: CGRect(x: 5, y: 6, width: 7, height: 8)),
            Selection.display(display),
        ])
    func exposesDisplayID(_ selection: Selection) {
        #expect(selection.displayID == Self.display)
    }
}
