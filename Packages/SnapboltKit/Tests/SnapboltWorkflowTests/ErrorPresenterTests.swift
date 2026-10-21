import Foundation
import SnapboltCore
import Testing

@testable import SnapboltWorkflow

@Suite("Error presenter")
struct ErrorPresenterTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let error: any Error
        let title: String
        let message: String
        let recovery: Recovery?
        var testDescription: String { String(describing: error) }
    }

    static let clip = "The image was copied to the clipboard."
    static let uploadFailed = "Upload failed"

    static let cases: [Case] = [
        Case(
            error: CaptureError.permissionDenied, title: "Screen Recording permission needed",
            message: "Allow Snapbolt in System Settings › Privacy & Security › Screen & System Audio Recording, "
                + "then try again.",
            recovery: .openPrivacySettings),
        Case(
            error: CaptureError.noDisplays, title: "Capture failed",
            message: "Snapbolt could not capture the screen. Try again.", recovery: nil),
        Case(
            error: UploadError.server(statusCode: 403, code: "InvalidAccessKeyId", message: nil), title: uploadFailed,
            message: "The access key or secret key is not valid. \(clip)", recovery: .openStorageSettings),
        Case(
            error: UploadError.server(statusCode: 403, code: "SignatureDoesNotMatch", message: nil),
            title: uploadFailed, message: "The access key or secret key is not valid. \(clip)",
            recovery: .openStorageSettings),
        Case(
            error: UploadError.server(statusCode: 404, code: "NoSuchBucket", message: nil), title: uploadFailed,
            message: "The bucket was not found. Check the bucket name. \(clip)", recovery: .openStorageSettings),
        Case(
            error: UploadError.server(statusCode: 403, code: "AccessDenied", message: nil), title: uploadFailed,
            message: "This key does not have write access to the bucket. \(clip)", recovery: .openStorageSettings),
        Case(
            error: UploadError.server(statusCode: 500, code: "InternalError", message: nil), title: uploadFailed,
            message: "The server returned HTTP 500 (InternalError). \(clip)", recovery: .openStorageSettings),
        Case(
            error: UploadError.server(statusCode: 502, code: nil, message: nil), title: uploadFailed,
            message: "The server returned HTTP 502. \(clip)", recovery: .openStorageSettings),
        Case(
            error: UploadError.network(.notConnectedToInternet), title: uploadFailed,
            message: "Could not reach the storage endpoint. Check your connection. \(clip)", recovery: nil),
        Case(
            error: UploadError.invalidEndpoint("x"), title: uploadFailed,
            message: "The storage endpoint is not valid. Check Settings. \(clip)", recovery: .openStorageSettings),
        Case(
            error: UploadError.invalidResponse, title: uploadFailed,
            message: "The storage endpoint is not valid. Check Settings. \(clip)", recovery: .openStorageSettings),
        Case(
            error: SettingsError.keychain(status: -25300), title: uploadFailed,
            message: "Could not read the secret key from the Keychain (error -25300). \(clip)",
            recovery: .openStorageSettings),
        Case(
            error: SettingsError.invalidEndpoint, title: uploadFailed,
            message: "Storage settings are not valid. Check Settings. \(clip)", recovery: .openStorageSettings),
        Case(
            error: FileSaveError.writeFailed(path: "/x"), title: "Could not save the local copy",
            message: "Check that the captures folder exists and is writable.", recovery: nil),
    ]

    @Test("Maps each error to its user-facing message", arguments: cases)
    func mapsError(_ testCase: Case) {
        let presented = ErrorPresenter.present(testCase.error)

        #expect(
            presented == UserFacingError(title: testCase.title, message: testCase.message, recovery: testCase.recovery))
    }

    @Test("Unknown errors fall back to their description")
    func unknownErrorFallsBack() {
        let presented = ErrorPresenter.present(CocoaError(.fileNoSuchFile))

        #expect(presented.title == "Something went wrong")
        #expect(presented.recovery == nil)
    }

    @Test("The not-configured message points to storage settings")
    func notConfigured() {
        #expect(
            ErrorPresenter.notConfigured
                == UserFacingError(
                    title: "Image copied to clipboard",
                    message: "Set up storage in Settings to get a link instead.",
                    recovery: .openStorageSettings))
    }
}
