/// Lets the user annotate a capture before it is saved and uploaded.
@MainActor
public protocol ImageEditing {
    /// Shows the editor and returns the edited image, or `nil` if the user cancelled.
    func edit(_ capture: CapturedImage) async -> EditedImage?
}
