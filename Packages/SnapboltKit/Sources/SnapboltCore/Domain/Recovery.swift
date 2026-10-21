/// An action the user can take to fix a problem.
public enum Recovery: Equatable, Sendable {
    /// Open the Storage tab of the settings window.
    case openStorageSettings
    /// Open the Screen Recording page of System Settings.
    case openPrivacySettings
}
