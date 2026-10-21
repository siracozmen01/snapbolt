/// Uploads encoded images to storage.
public protocol Uploading: Sendable {
    /// Uploads `image` and returns its key and public URL.
    /// - Throws: ``UploadError``.
    func upload(_ image: EncodedImage, using settings: StorageSettings) async throws -> UploadResult
}
