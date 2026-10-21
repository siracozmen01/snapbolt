/// Identifies a physical display; wraps the CoreGraphics display ID.
public struct DisplayID: Hashable, Sendable {
    /// The `CGDirectDisplayID` value.
    public let rawValue: UInt32

    /// Creates an identifier from a `CGDirectDisplayID`.
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
}
