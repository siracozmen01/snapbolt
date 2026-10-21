/// The result of checking storage settings with a test upload.
public enum ConnectionTestOutcome: Equatable, Sendable {
    /// Upload, public read and delete all worked.
    case success
    /// A step failed.
    case failure(ConnectionTestFailure)
}
