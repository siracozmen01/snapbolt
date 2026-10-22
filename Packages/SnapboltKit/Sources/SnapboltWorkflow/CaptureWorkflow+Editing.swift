import SnapboltCore

extension CaptureWorkflow {
    /// The image to continue with and where it goes: the capture itself when the editor is off, the editor's
    /// result when it is on, or `nil` when the user cancelled the editor.
    func edit(_ captured: CapturedImage, preferences: CapturePreferences) async -> EditedImage? {
        guard preferences.opensEditor else { return EditedImage(image: captured.image, destination: .upload) }
        guard let edited = await dependencies.editor.edit(captured) else {
            logger.info("Editor cancelled")
            return nil
        }
        logger.info("Editor finished: \(String(describing: edited.destination), privacy: .public)")
        return edited
    }

    /// Uploads and copies the link, or copies the image itself when the user chose Copy in the editor.
    func deliver(_ image: EncodedImage, to destination: EditedImage.Destination) async {
        switch destination {
        case .upload:
            await uploadAndCopyLink(image)
        case .clipboard:
            dependencies.clipboard.writeImage(image)
        }
    }
}
