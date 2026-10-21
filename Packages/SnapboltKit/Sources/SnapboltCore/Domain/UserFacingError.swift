/// An error as shown to the user in a notification or window.
public struct UserFacingError: Equatable, Sendable {
    /// A short headline, e.g. "Upload failed".
    public let title: String
    /// What happened and what to do, in plain language.
    public let message: String
    /// An action that helps fix the problem, if there is one.
    public let recovery: Recovery?

    /// Creates a user-facing error.
    public init(title: String, message: String, recovery: Recovery?) {
        self.title = title
        self.message = message
        self.recovery = recovery
    }
}
