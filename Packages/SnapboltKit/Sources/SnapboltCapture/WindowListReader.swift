import CoreGraphics
import Foundation
import SnapboltCore

/// Reads on-screen windows front to back from the window server.
///
/// `CGWindowListCopyWindowInfo` is used instead of ScreenCaptureKit's window list because it
/// guarantees front-to-back order, which window selection relies on.
enum WindowListReader {
    private static let minimumSide: CGFloat = 40

    static func windows(excludingProcess processID: pid_t) -> [WindowInfo] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return [] }
        let primaryHeight = CGDisplayBounds(CGMainDisplayID()).height
        return list.compactMap { window(from: $0, excluding: processID, primaryHeight: primaryHeight) }
    }

    private static func window(from entry: [String: Any], excluding processID: pid_t, primaryHeight: CGFloat)
        -> WindowInfo?
    {
        guard
            entry[kCGWindowLayer as String] as? Int == 0,
            entry[kCGWindowOwnerPID as String] as? pid_t != processID,
            let number = entry[kCGWindowNumber as String] as? UInt32,
            let boundsDictionary = entry[kCGWindowBounds as String] as? NSDictionary,
            let quartzBounds = CGRect(dictionaryRepresentation: boundsDictionary),
            quartzBounds.width >= minimumSide, quartzBounds.height >= minimumSide
        else { return nil }
        return WindowInfo(
            id: number,
            ownerName: entry[kCGWindowOwnerName as String] as? String,
            title: entry[kCGWindowName as String] as? String,
            frameInGlobalPoints: CoordinateConversion.globalPointsRect(
                fromQuartzRect: quartzBounds, primaryDisplayHeight: primaryHeight)
        )
    }
}
