import Foundation

/// Why an upload failed.
public enum UploadError: Error, Equatable, Sendable {
    /// The endpoint or bucket does not form a valid request URL.
    case invalidEndpoint(String)
    /// The request did not reach the server.
    case network(URLError.Code)
    /// The server answered with an error status; `code` and `message` come from the S3 XML error body.
    case server(statusCode: Int, code: String?, message: String?)
    /// The server's answer was not an HTTP response.
    case invalidResponse
}
