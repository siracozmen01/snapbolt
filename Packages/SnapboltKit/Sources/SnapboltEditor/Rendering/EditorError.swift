/// Failures inside the editor. They never leave the module: the editor shows them and stays open.
enum EditorError: Error, Equatable {
    /// The edited image could not be produced (for example, no bitmap context).
    case exportFailed
}
