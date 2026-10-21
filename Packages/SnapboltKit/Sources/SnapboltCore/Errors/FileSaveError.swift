/// Why a local copy of a capture could not be written.
public enum FileSaveError: Error, Equatable, Sendable {
    /// The folder cannot be created or written to.
    case folderNotWritable(path: String)
    /// Writing the file failed.
    case writeFailed(path: String)
}
