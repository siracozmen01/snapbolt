import Foundation
import SnapboltCore
import Testing

@testable import SnapboltUpload

/// Runs against a real bucket only when every `SNAPBOLT_IT_*` variable is set. Never runs in CI.
@Suite("S3 uploader against a real bucket", .enabled(if: IntegrationSettings.load() != nil))
struct S3UploaderIntegrationTests {
    /// A valid 1×1 PNG.
    static let png = Data(
        base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=")

    @Test("Uploads, serves publicly and deletes an object")
    func uploadsServesAndDeletes() async throws {
        let settings = try #require(IntegrationSettings.load())
        let image = EncodedImage(data: try #require(Self.png), contentType: "image/png", fileExtension: "png")

        let result = try await S3Uploader().upload(image, using: settings)
        let (body, response) = try await URLSession.shared.data(from: result.publicURL)
        try await S3Client(settings: settings, session: .shared, now: Date.init).delete(key: result.objectKey)

        #expect((response as? HTTPURLResponse)?.statusCode == 200)
        #expect(body == image.data)
    }
}

enum IntegrationSettings {
    static func load() -> StorageSettings? {
        let environment = ProcessInfo.processInfo.environment
        func value(_ name: String) -> String? { environment["SNAPBOLT_IT_\(name)"].flatMap { $0.isEmpty ? nil : $0 } }
        guard
            let endpoint = value("ENDPOINT").flatMap(URL.init(string:)),
            let region = value("REGION"), let bucket = value("BUCKET"),
            let accessKeyID = value("ACCESS_KEY_ID"), let secret = value("SECRET_ACCESS_KEY"),
            let publicBaseURL = value("PUBLIC_BASE_URL").flatMap(URL.init(string:))
        else { return nil }
        return StorageSettings(
            endpoint: endpoint, region: region, bucket: bucket, accessKeyID: accessKeyID,
            secretAccessKey: secret, publicBaseURL: publicBaseURL, keyTemplate: .defaultTemplate)
    }
}
