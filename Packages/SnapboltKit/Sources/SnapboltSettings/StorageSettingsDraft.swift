import Foundation
import SnapboltCore

/// Storage settings as the user typed them, before validation.
public struct StorageSettingsDraft: Equatable, Sendable {
    /// The S3 API endpoint as typed.
    public var endpoint: String
    /// The signing region as typed.
    public var region: String
    /// The bucket name as typed.
    public var bucket: String
    /// The access key ID as typed.
    public var accessKeyID: String
    /// The secret access key as typed.
    public var secretAccessKey: String
    /// The public base URL as typed.
    public var publicBaseURL: String
    /// The object key template as typed.
    public var keyTemplate: String

    /// Creates a draft.
    public init(
        endpoint: String, region: String, bucket: String, accessKeyID: String, secretAccessKey: String,
        publicBaseURL: String, keyTemplate: String
    ) {
        self.endpoint = endpoint
        self.region = region
        self.bucket = bucket
        self.accessKeyID = accessKeyID
        self.secretAccessKey = secretAccessKey
        self.publicBaseURL = publicBaseURL
        self.keyTemplate = keyTemplate
    }

    private var fields: [(name: String, value: String)] {
        [
            (String(localized: "Endpoint"), endpoint), (String(localized: "Region"), region),
            (String(localized: "Bucket"), bucket), (String(localized: "Access Key ID"), accessKeyID),
            (String(localized: "Secret Access Key"), secretAccessKey),
            (String(localized: "Public base URL"), publicBaseURL), (String(localized: "Key template"), keyTemplate),
        ]
    }

    /// Whether every field has a value.
    public var isComplete: Bool {
        fields.allSatisfy { !$0.value.trimmed.isEmpty }
    }

    /// Validates and normalises the draft: adds a missing `https://`, drops trailing slashes, trims spaces.
    /// - Throws: ``SettingsError`` naming the first problem.
    public func validated() throws(SettingsError) -> StorageSettings {
        if let missing = fields.first(where: { $0.value.trimmed.isEmpty }) { throw .missingField(missing.name) }
        guard let endpointURL = Self.normalizedURL(endpoint, schemes: ["https"], allowsPath: false) else {
            throw .invalidEndpoint
        }
        guard let baseURL = Self.normalizedURL(publicBaseURL, schemes: ["http", "https"], allowsPath: true) else {
            throw .invalidPublicBaseURL
        }
        let template: ObjectKeyTemplate
        do {
            template = try ObjectKeyTemplate(validating: keyTemplate)
        } catch {
            throw .invalidKeyTemplate(error)
        }
        return StorageSettings(
            endpoint: endpointURL, region: region.trimmed, bucket: bucket.trimmed, accessKeyID: accessKeyID.trimmed,
            secretAccessKey: secretAccessKey.trimmed, publicBaseURL: baseURL, keyTemplate: template)
    }

    private static func normalizedURL(_ raw: String, schemes: Set<String>, allowsPath: Bool) -> URL? {
        var text = raw.trimmed
        if !text.contains("://") { text = "https://" + text }
        while text.hasSuffix("/") {
            text.removeLast()
        }
        guard
            let components = URLComponents(string: text),
            let scheme = components.scheme?.lowercased(), schemes.contains(scheme),
            let host = components.host, !host.isEmpty,
            components.query == nil, components.fragment == nil,
            allowsPath || components.path.isEmpty
        else { return nil }
        return components.url
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
