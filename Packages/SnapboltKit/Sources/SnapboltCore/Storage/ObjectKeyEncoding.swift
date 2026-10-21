import Foundation

/// Percent-encoding for object key segments, shared by public links and request signing.
public enum ObjectKeyEncoding {
    /// RFC 3986 unreserved characters; everything else is encoded.
    private static let unreserved = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

    /// Percent-encodes one path segment (no `/`) using the RFC 3986 unreserved set.
    public static func percentEncodedSegment(_ segment: String) -> String {
        guard let encoded = segment.addingPercentEncoding(withAllowedCharacters: unreserved) else {
            preconditionFailure("Percent-encoding a valid Swift string cannot fail")
        }
        return encoded
    }
}
