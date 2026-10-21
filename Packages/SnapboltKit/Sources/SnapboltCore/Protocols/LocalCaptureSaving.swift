import Foundation

/// Writes local copies of captures.
public protocol LocalCaptureSaving: Sendable {
    /// Saves `image` below `folder` and returns the file URL.
    /// - Throws: ``FileSaveError``.
    func save(_ image: EncodedImage, capturedAt: Date, in folder: URL) throws -> URL
}
