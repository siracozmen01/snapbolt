import Foundation
import SnapboltCore

/// The SigV4 canonical form of a request: method, URI, query, headers and payload hash.
///
/// S3 differs from other AWS services in one detail: path segments are percent-encoded once,
/// not twice.
struct CanonicalRequest {
    /// The lowercased, sorted header names joined with `;`.
    let signedHeaders: String
    /// The newline-separated canonical request that gets hashed into the string to sign.
    let text: String

    init(request: URLRequest, payloadHash: String) {
        let url = request.url ?? URL(filePath: "/")
        let headers = Self.canonicalHeaders(of: request, url: url)
        signedHeaders = headers.map(\.name).joined(separator: ";")
        text = [
            request.httpMethod ?? "GET",
            Self.canonicalURI(of: url),
            Self.canonicalQuery(of: url),
            headers.map { "\($0.name):\($0.value)\n" }.joined(),
            signedHeaders,
            payloadHash,
        ].joined(separator: "\n")
    }

    private static func canonicalURI(of url: URL) -> String {
        let path = url.path(percentEncoded: false)
        guard !path.isEmpty, path != "/" else { return "/" }
        return path.split(separator: "/", omittingEmptySubsequences: false)
            .map { ObjectKeyEncoding.percentEncodedSegment(String($0)) }
            .joined(separator: "/")
    }

    private static func canonicalQuery(of url: URL) -> String {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return
            items
            .map {
                (
                    ObjectKeyEncoding.percentEncodedSegment($0.name),
                    ObjectKeyEncoding.percentEncodedSegment($0.value ?? "")
                )
            }
            .sorted { $0 < $1 }
            .map { "\($0.0)=\($0.1)" }
            .joined(separator: "&")
    }

    private static func canonicalHeaders(of request: URLRequest, url: URL) -> [(name: String, value: String)] {
        var headers = ["host": hostHeader(of: url)]
        for (name, value) in request.allHTTPHeaderFields ?? [:] {
            headers[name.lowercased()] = normalized(value)
        }
        return headers.sorted { $0.key < $1.key }.map { (name: $0.key, value: $0.value) }
    }

    private static func hostHeader(of url: URL) -> String {
        let host = url.host(percentEncoded: false) ?? ""
        guard let port = url.port, port != defaultPort(for: url.scheme) else { return host }
        return "\(host):\(port)"
    }

    private static func defaultPort(for scheme: String?) -> Int? {
        switch scheme {
        case "https": 443
        case "http": 80
        default: nil
        }
    }

    private static func normalized(_ value: String) -> String {
        value.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
