import Foundation

/// User preferences that affect what happens to a capture locally.
public struct CapturePreferences: Equatable, Sendable {
    /// Whether a copy of every capture is written to ``folder``.
    public let saveLocally: Bool
    /// The root folder for local copies.
    public let folder: URL

    /// Creates capture preferences.
    public init(saveLocally: Bool, folder: URL) {
        self.saveLocally = saveLocally
        self.folder = folder
    }
}
