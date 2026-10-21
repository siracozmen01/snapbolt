import Foundation
import SnapboltCore
import Testing

@testable import SnapboltSettings

@Suite("Storage settings draft")
struct StorageSettingsDraftTests {
    func draft(
        endpoint: String = "https://acc.r2.cloudflarestorage.com", publicBaseURL: String = "https://i.example.com",
        bucket: String = "shots", keyTemplate: String = "{yyyy}/{MM}/{random}"
    ) -> StorageSettingsDraft {
        StorageSettingsDraft(
            endpoint: endpoint, region: "auto", bucket: bucket, accessKeyID: "KEY", secretAccessKey: "SECRET",
            publicBaseURL: publicBaseURL, keyTemplate: keyTemplate)
    }

    @Test("Adds https and drops a trailing slash on the endpoint")
    func normalisesEndpointWithoutSchemeAndTrailingSlash() throws {
        let settings = try draft(endpoint: " acc.r2.cloudflarestorage.com/ ").validated()

        #expect(settings.endpoint.absoluteString == "https://acc.r2.cloudflarestorage.com")
    }

    @Test("Rejects an endpoint that includes the bucket in its path")
    func rejectsEndpointWithBucketInPath() {
        #expect(throws: SettingsError.invalidEndpoint) {
            try draft(endpoint: "https://acc.r2.cloudflarestorage.com/shots").validated()
        }
    }

    @Test("Rejects a plain http endpoint")
    func rejectsHTTPEndpoint() {
        #expect(throws: SettingsError.invalidEndpoint) {
            try draft(endpoint: "http://acc.r2.cloudflarestorage.com").validated()
        }
    }

    @Test("Keeps the public base URL path and drops the trailing slash")
    func keepsPublicBaseURLPathWithoutTrailingSlash() throws {
        let settings = try draft(publicBaseURL: "https://cdn.example.com/shots/").validated()

        #expect(settings.publicBaseURL.absoluteString == "https://cdn.example.com/shots")
    }

    @Test("Adds https to a public base URL typed without a scheme")
    func addsSchemeToPublicBaseURL() throws {
        let settings = try draft(publicBaseURL: "i.example.com").validated()

        #expect(settings.publicBaseURL.absoluteString == "https://i.example.com")
    }

    @Test("Rejects a key template without {random}")
    func rejectsInvalidKeyTemplate() {
        #expect(throws: SettingsError.invalidKeyTemplate(.missingRandomToken)) {
            try draft(keyTemplate: "{yyyy}").validated()
        }
    }

    @Test("Names the first missing field")
    func reportsMissingField() {
        #expect(throws: SettingsError.missingField("Bucket")) {
            try draft(bucket: "  ").validated()
        }
        #expect(!draft(bucket: "").isComplete)
        #expect(draft().isComplete)
    }
}
