import CryptoKit
import Foundation
import SnapboltCore
import SnapboltTestSupport
import Testing

@testable import SnapboltUpload

@Suite("S3 uploader")
struct S3UploaderTests {
    static let now = Date(timeIntervalSince1970: 1_792_576_800)  // 2026-10-21 UTC
    static let image = EncodedImage(data: Data("png-bytes".utf8), contentType: "image/png", fileExtension: "png")
    static let signatureError = "<Error><Code>SignatureDoesNotMatch</Code><Message>m</Message></Error>"

    let sleeps = SleepRecorder()

    func makeUploader(_ server: StubServer) -> S3Uploader {
        let sleeps = sleeps
        return S3Uploader(
            session: server.session, now: { Self.now }, randomToken: { "abcdefghij" },
            sleep: { await sleeps.sleep($0) }, timeZone: .gmt)
    }

    @Test("Puts to a path-style URL with the required headers")
    func putsToPathStyleURLWithHeaders() async throws {
        let server = StubServer([.status(200)])

        _ = try await makeUploader(server).upload(Self.image, using: .fixture())

        let request = try #require(server.requests.first)
        #expect(server.requests.count == 1)
        #expect(request.method == "PUT")
        #expect(request.url.absoluteString == "https://acc.r2.cloudflarestorage.com/shots/2026/10/abcdefghij.png")
        #expect(request.header("Content-Type") == "image/png")
        #expect(request.header("Cache-Control") == "public, max-age=31536000, immutable")
        #expect(request.header("x-amz-content-sha256") == SHA256.hash(data: Self.image.data).hexString)
        #expect(request.body == Self.image.data)
        let authorization = try #require(request.header("Authorization"))
        #expect(authorization.hasPrefix("AWS4-HMAC-SHA256 Credential=KEY/20261021/auto/s3/aws4_request,"))
        #expect(request.header("x-amz-acl") == nil)
    }

    @Test("Returns the key and the public URL")
    func returnsPublicURLFromBaseURL() async throws {
        let result = try await makeUploader(StubServer([.status(200)])).upload(Self.image, using: .fixture())

        #expect(result.objectKey == "2026/10/abcdefghij.png")
        #expect(result.publicURL.absoluteString == "https://i.example.com/2026/10/abcdefghij.png")
    }

    @Test("Retries server errors, then succeeds")
    func retriesServerErrorsThenSucceeds() async throws {
        let server = StubServer([.status(500), .status(503), .status(200)])

        _ = try await makeUploader(server).upload(Self.image, using: .fixture())

        #expect(server.requests.count == 3)
        #expect(await sleeps.durations == [.seconds(1), .seconds(2)])
    }

    @Test("Gives up after two retries")
    func givesUpAfterTwoRetries() async {
        let server = StubServer([.status(500)])

        await #expect(throws: UploadError.server(statusCode: 500, code: nil, message: nil)) {
            try await makeUploader(server).upload(Self.image, using: .fixture())
        }
        #expect(server.requests.count == 3)
    }

    @Test("Does not retry client errors")
    func doesNotRetryClientErrors() async {
        let server = StubServer([.status(403, body: Self.signatureError)])

        await #expect(throws: UploadError.server(statusCode: 403, code: "SignatureDoesNotMatch", message: "m")) {
            try await makeUploader(server).upload(Self.image, using: .fixture())
        }
        #expect(server.requests.count == 1)
    }

    @Test("Retries network errors")
    func retriesNetworkErrors() async {
        let server = StubServer([.failure(.notConnectedToInternet)])

        await #expect(throws: UploadError.network(.notConnectedToInternet)) {
            try await makeUploader(server).upload(Self.image, using: .fixture())
        }
        #expect(server.requests.count == 3)
    }
}

extension SHA256.Digest {
    var hexString: String { map { String(format: "%02x", $0) }.joined() }
}
