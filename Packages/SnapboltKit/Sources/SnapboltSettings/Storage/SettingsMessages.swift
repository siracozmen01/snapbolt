import SnapboltCore

/// Plain-language messages for settings validation errors.
enum SettingsMessages {
    static func message(for error: SettingsError) -> String {
        switch error {
        case .invalidEndpoint:
            String(
                localized:
                    "Endpoint must be an https URL without a path, e.g. https://<account-id>.r2.cloudflarestorage.com")
        case .invalidPublicBaseURL:
            String(localized: "Public base URL must be an http(s) URL, e.g. https://i.example.com")
        case .invalidKeyTemplate(.missingRandomToken):
            String(localized: "The key template must contain {random}.")
        case .invalidKeyTemplate(.unknownToken(let token)):
            String(localized: "Unknown token \(token).")
        case .invalidKeyTemplate(.empty):
            String(localized: "Key template is required.")
        case .missingField(let field):
            String(localized: "\(field) is required.")
        case .keychain(let status):
            String(localized: "Could not access the Keychain (error \(String(status))).")
        }
    }
}
