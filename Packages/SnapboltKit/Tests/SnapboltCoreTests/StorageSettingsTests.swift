import Foundation
import Testing

@testable import SnapboltCore

@Suite("Storage settings")
struct StorageSettingsTests {
    @Test(
        "Joins the public base URL and an object key",
        arguments: [
            ("https://i.example.com", "2026/10/a b.png", "https://i.example.com/2026/10/a%20b.png"),
            ("https://i.example.com/", "2026/10/x.png", "https://i.example.com/2026/10/x.png"),
            ("https://cdn.example.com/shots/", "x.png", "https://cdn.example.com/shots/x.png"),
            ("https://i.example.com", "a+b/ü.png", "https://i.example.com/a%2Bb/%C3%BC.png"),
        ]
    )
    func publicURLJoinsBaseAndKey(base: String, key: String, expected: String) throws {
        let settings = try makeSettings(publicBaseURL: base)

        #expect(settings.publicURL(forObjectKey: key).absoluteString == expected)
    }

    private func makeSettings(publicBaseURL: String) throws -> StorageSettings {
        StorageSettings(
            endpoint: try #require(URL(string: "https://acc.r2.cloudflarestorage.com")),
            region: "auto",
            bucket: "shots",
            accessKeyID: "KEY",
            secretAccessKey: "SECRET",
            publicBaseURL: try #require(URL(string: publicBaseURL)),
            keyTemplate: .defaultTemplate
        )
    }
}
