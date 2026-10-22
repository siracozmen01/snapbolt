import CoreGraphics

/// What the user chose to capture. Rects are in the display's pixels (origin top-left, y down).
public enum Selection: Equatable, Sendable {
    /// A dragged region on one display.
    case region(DisplayID, rectInPixels: CGRect)
    /// A window's frame, clipped to the display where it was clicked.
    case window(DisplayID, rectInPixels: CGRect)
    /// A whole display.
    case display(DisplayID)
}

extension Selection {
    /// The display the selection was made on.
    public var displayID: DisplayID {
        switch self {
        case .region(let id, _), .window(let id, _), .display(let id):
            id
        }
    }
}
