import Foundation

/// Why a storage connection test failed.
public enum ConnectionTestFailure: Equatable, Sendable {
    /// The endpoint host could not be reached or is not a valid URL.
    case invalidEndpoint
    /// The access key or secret key was rejected.
    case invalidCredentials
    /// The bucket does not exist.
    case bucketNotFound
    /// The key cannot write to the bucket.
    case accessDenied
    /// The test object was uploaded but could not be read through the public base URL.
    case publicURLUnreachable(statusCode: Int?)
    /// A network error other than an unreachable host.
    case network(URLError.Code)
    /// Any other server response.
    case unexpected(statusCode: Int, code: String?)

    /// A plain-language explanation shown in the settings window.
    public var message: String {
        switch self {
        case .invalidEndpoint:
            String(localized: "The endpoint could not be reached. Check the endpoint URL.")
        case .invalidCredentials:
            String(localized: "The access key or secret key is not valid.")
        case .bucketNotFound:
            String(localized: "The bucket was not found. Check the bucket name.")
        case .accessDenied:
            String(localized: "This key does not have write access to the bucket.")
        case .publicURLUnreachable(let statusCode):
            Self.publicURLMessage(statusCode: statusCode)
        case .network:
            String(localized: "Could not connect. Check your internet connection.")
        case .unexpected(let statusCode, let code):
            code.map { String(localized: "Unexpected response: HTTP \(statusCode) (\($0)).") }
                ?? String(localized: "Unexpected response: HTTP \(statusCode).")
        }
    }

    private static func publicURLMessage(statusCode: Int?) -> String {
        let advice = String(localized: "Check the public base URL and that public access is enabled on the bucket.")
        guard let statusCode else {
            return String(localized: "Upload worked, but the public URL could not be reached. \(advice)")
        }
        return String(localized: "Upload worked, but the public URL returned HTTP \(statusCode). \(advice)")
    }
}
