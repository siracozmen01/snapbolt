/// Why storage settings could not be read, saved or validated.
public enum SettingsError: Error, Equatable, Sendable {
    /// A Keychain call failed with this `OSStatus`.
    case keychain(status: Int32)
    /// The endpoint is not an https URL without a path.
    case invalidEndpoint
    /// The public base URL is not an http(s) URL.
    case invalidPublicBaseURL
    /// A required field is empty; the associated value is the field's display name.
    case missingField(String)
    /// The object key template is not valid.
    case invalidKeyTemplate(ObjectKeyTemplate.ValidationError)
}
