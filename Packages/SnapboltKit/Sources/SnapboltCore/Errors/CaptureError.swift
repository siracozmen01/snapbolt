/// Why freezing, cropping or encoding a capture failed.
public enum CaptureError: Error, Equatable, Sendable {
    /// Screen Recording permission is not granted.
    case permissionDenied
    /// No display could be captured.
    case noDisplays
    /// The selection refers to a display that was not captured.
    case displayNotFound
    /// The selection has no pixels.
    case emptySelection
    /// The image could not be encoded.
    case encodingFailed
    /// ScreenCaptureKit reported another error, described by the message.
    case captureFailed(String)
}
