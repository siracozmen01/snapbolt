import Foundation

/// Everything needed to upload to an S3-compatible bucket and build public links.
public struct StorageSettings: Equatable, Sendable {
    /// The S3 API endpoint, e.g. `https://<account-id>.r2.cloudflarestorage.com`.
    public let endpoint: URL
    /// The signing region; `auto` for Cloudflare R2.
    public let region: String
    /// The bucket name.
    public let bucket: String
    /// The access key ID.
    public let accessKeyID: String
    /// The secret access key. Stored in the Keychain, never logged.
    public let secretAccessKey: String
    /// The base of public links, e.g. `https://i.example.com`.
    public let publicBaseURL: URL
    /// How object keys are named.
    public let keyTemplate: ObjectKeyTemplate

    /// Creates storage settings.
    public init(
        endpoint: URL,
        region: String,
        bucket: String,
        accessKeyID: String,
        secretAccessKey: String,
        publicBaseURL: URL,
        keyTemplate: ObjectKeyTemplate
    ) {
        self.endpoint = endpoint
        self.region = region
        self.bucket = bucket
        self.accessKeyID = accessKeyID
        self.secretAccessKey = secretAccessKey
        self.publicBaseURL = publicBaseURL
        self.keyTemplate = keyTemplate
    }

    /// Returns the public link for `key`: the base URL plus each key segment, percent-encoded.
    public func publicURL(forObjectKey key: String) -> URL {
        var base = publicBaseURL.absoluteString
        while base.hasSuffix("/") {
            base.removeLast()
        }
        let path = key.split(separator: "/", omittingEmptySubsequences: false)
            .map { ObjectKeyEncoding.percentEncodedSegment(String($0)) }
            .joined(separator: "/")
        guard let url = URL(string: base + "/" + path) else {
            preconditionFailure("A valid base URL followed by percent-encoded segments is always a valid URL")
        }
        return url
    }
}
