import AppKit
import SnapboltCore

/// AppKit's view of one display: its frame in global points and its scale.
struct ScreenGeometry: Sendable {
    let id: DisplayID
    let frameInGlobalPoints: CGRect
    let scale: CGFloat
}

/// Reads display geometry and the cursor position from AppKit, which must happen on the main actor.
@MainActor
enum DisplayScaleReader {
    private static let screenNumberKey = NSDeviceDescriptionKey("NSScreenNumber")

    static func screens() -> [ScreenGeometry] {
        NSScreen.screens.compactMap { screen in
            guard let number = screen.deviceDescription[screenNumberKey] as? NSNumber else { return nil }
            return ScreenGeometry(
                id: DisplayID(rawValue: number.uint32Value), frameInGlobalPoints: screen.frame,
                scale: screen.backingScaleFactor)
        }
    }

    static func cursorLocationInGlobalPoints() -> CGPoint {
        NSEvent.mouseLocation
    }
}
