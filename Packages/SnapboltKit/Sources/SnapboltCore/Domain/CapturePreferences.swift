import Foundation

/// User preferences that affect what happens to a capture locally.
public struct CapturePreferences: Equatable, Sendable {
    /// Whether a copy of every capture is written to ``folder``.
    public let saveLocally: Bool
    /// The root folder for local copies.
    public let folder: URL
    /// Whether every capture opens in the editor before it is saved and uploaded.
    public let opensEditor: Bool

    /// Creates capture preferences.
    public init(saveLocally: Bool, folder: URL, opensEditor: Bool = false) {
        self.saveLocally = saveLocally
        self.folder = folder
        self.opensEditor = opensEditor
    }
}
