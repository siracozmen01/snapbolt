import Foundation
import SnapboltCore

/// Turns domain errors into the messages users see. The only place this mapping happens.
public enum ErrorPresenter {
    /// Shown when a capture finished but storage is not configured.
    public static let notConfigured = UserFacingError(
        title: String(localized: "Image copied to clipboard"),
        message: String(localized: "Set up storage in Settings to get a link instead."),
        recovery: .openStorageSettings
    )

    private static let uploadFailed = String(localized: "Upload failed")
    private static let imageCopied = String(localized: "The image was copied to the clipboard.")

    /// Returns the user-facing version of `error`.
    public static func present(_ error: any Error) -> UserFacingError {
        switch error {
        case let error as CaptureError:
            present(error)
        case let error as UploadError:
            present(error)
        case let error as SettingsError:
            present(error)
        case is FileSaveError:
            UserFacingError(
                title: String(localized: "Could not save the local copy"),
                message: String(localized: "Check that the captures folder exists and is writable."),
                recovery: nil
            )
        default:
            UserFacingError(
                title: String(localized: "Something went wrong"), message: error.localizedDescription, recovery: nil)
        }
    }

    private static func present(_ error: CaptureError) -> UserFacingError {
        guard error == .permissionDenied else {
            return UserFacingError(
                title: String(localized: "Capture failed"),
                message: String(localized: "Snapbolt could not capture the screen. Try again."),
                recovery: nil
            )
        }
        return UserFacingError(
            title: String(localized: "Screen Recording permission needed"),
            message: String(
                localized: """
                    Allow Snapbolt in System Settings › Privacy & Security › Screen & System Audio Recording, \
                    then try again.
                    """),
            recovery: .openPrivacySettings
        )
    }

    private static func present(_ error: UploadError) -> UserFacingError {
        switch error {
        case .server(let statusCode, let code, _):
            uploadFailure(serverMessage(statusCode: statusCode, code: code), recovery: .openStorageSettings)
        case .network:
            uploadFailure(
                String(localized: "Could not reach the storage endpoint. Check your connection."), recovery: nil)
        case .invalidEndpoint, .invalidResponse:
            uploadFailure(
                String(localized: "The storage endpoint is not valid. Check Settings."),
                recovery: .openStorageSettings)
        }
    }

    private static func serverMessage(statusCode: Int, code: String?) -> String {
        switch code {
        case "InvalidAccessKeyId", "SignatureDoesNotMatch":
            String(localized: "The access key or secret key is not valid.")
        case "NoSuchBucket":
            String(localized: "The bucket was not found. Check the bucket name.")
        case "AccessDenied":
            String(localized: "This key does not have write access to the bucket.")
        case let code?:
            String(localized: "The server returned HTTP \(String(statusCode)) (\(code)).")
        case nil:
            String(localized: "The server returned HTTP \(String(statusCode)).")
        }
    }

    private static func present(_ error: SettingsError) -> UserFacingError {
        guard case .keychain(let status) = error else {
            return uploadFailure(
                String(localized: "Storage settings are not valid. Check Settings."), recovery: .openStorageSettings)
        }
        return uploadFailure(
            String(localized: "Could not read the secret key from the Keychain (error \(String(status)))."),
            recovery: .openStorageSettings
        )
    }

    private static func uploadFailure(_ reason: String, recovery: Recovery?) -> UserFacingError {
        UserFacingError(title: uploadFailed, message: "\(reason) \(imageCopied)", recovery: recovery)
    }
}
