import CryptoKit
import Foundation

/// The key pair a request is signed with.
struct SigningCredentials: Sendable {
    let accessKeyID: String
    let secretAccessKey: String
}

/// Signs requests with AWS Signature Version 4 (header-based).
struct SigV4Signer: Sendable {
    private static let algorithm = "AWS4-HMAC-SHA256"

    /// The signing region, e.g. `auto` for Cloudflare R2.
    let region: String
    /// The signing service, `s3` for object storage.
    let service: String

    /// Returns `request` with `x-amz-date` and `Authorization` set.
    /// - Parameter payloadHash: The lowercase hex SHA-256 of the body.
    func sign(_ request: URLRequest, payloadHash: String, credentials: SigningCredentials, date: Date) -> URLRequest {
        let timestamp = SigningTimestamp(date)
        var signed = request
        signed.setValue(timestamp.dateTime, forHTTPHeaderField: "x-amz-date")
        let canonical = CanonicalRequest(request: signed, payloadHash: payloadHash)
        let scope = "\(timestamp.day)/\(region)/\(service)/aws4_request"
        let stringToSign = [Self.algorithm, timestamp.dateTime, scope, Self.hexSHA256(canonical.text)]
            .joined(separator: "\n")
        let signature = Self.hex(
            HMAC<SHA256>.authenticationCode(
                for: Data(stringToSign.utf8), using: signingKey(secret: credentials.secretAccessKey, day: timestamp.day)
            ))
        signed.setValue(
            "\(Self.algorithm) Credential=\(credentials.accessKeyID)/\(scope),"
                + "SignedHeaders=\(canonical.signedHeaders),Signature=\(signature)",
            forHTTPHeaderField: "Authorization"
        )
        return signed
    }

    /// Returns the lowercase hex SHA-256 of `data`.
    static func hexSHA256(_ data: Data) -> String {
        hex(SHA256.hash(data: data))
    }

    private static func hexSHA256(_ text: String) -> String {
        hexSHA256(Data(text.utf8))
    }

    private func signingKey(secret: String, day: String) -> SymmetricKey {
        let parts = [day, region, service, "aws4_request"]
        let initial = SymmetricKey(data: Data("AWS4\(secret)".utf8))
        return parts.reduce(initial) { key, part in
            SymmetricKey(data: Data(HMAC<SHA256>.authenticationCode(for: Data(part.utf8), using: key)))
        }
    }

    private static func hex<Bytes: Sequence>(_ bytes: Bytes) -> String where Bytes.Element == UInt8 {
        bytes.map { String(format: "%02x", $0) }.joined()
    }
}

/// The two UTC date formats SigV4 uses.
private struct SigningTimestamp {
    /// `yyyyMMdd'T'HHmmss'Z'`
    let dateTime: String
    /// `yyyyMMdd`
    let day: String

    init(_ date: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        func padded(_ value: Int?, _ width: Int) -> String {
            String(format: "%0\(width)d", value ?? 0)
        }
        day = padded(parts.year, 4) + padded(parts.month, 2) + padded(parts.day, 2)
        dateTime = day + "T" + padded(parts.hour, 2) + padded(parts.minute, 2) + padded(parts.second, 2) + "Z"
    }
}
