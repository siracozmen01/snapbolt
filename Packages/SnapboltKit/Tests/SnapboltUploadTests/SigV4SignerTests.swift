import Foundation
import Testing

@testable import SnapboltUpload

/// Vectors come from AWS: the S3 "GET Object" example in the S3 API reference
/// (sig-v4-header-based-auth) and `get-vanilla` from the AWS SigV4 test suite.
@Suite("SigV4 signer")
struct SigV4SignerTests {
    static let emptyPayloadHash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    static let s3Credentials = SigningCredentials(
        accessKeyID: "AKIAIOSFODNN7EXAMPLE", secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")

    @Test("Builds the canonical request from the AWS S3 GET Object example")
    func buildsAWSCanonicalRequest() throws {
        var request = try getObjectRequest()
        request.setValue("20130524T000000Z", forHTTPHeaderField: "x-amz-date")

        let canonical = CanonicalRequest(request: request, payloadHash: Self.emptyPayloadHash)

        #expect(
            canonical.text == """
                GET
                /test.txt

                host:examplebucket.s3.amazonaws.com
                range:bytes=0-9
                x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
                x-amz-date:20130524T000000Z

                host;range;x-amz-content-sha256;x-amz-date
                e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
                """)
    }

    @Test("Matches the AWS S3 GET Object example signature")
    func matchesAWSGetObjectExample() throws {
        let signer = SigV4Signer(region: "us-east-1", service: "s3")

        let signed = signer.sign(
            try getObjectRequest(), payloadHash: Self.emptyPayloadHash, credentials: Self.s3Credentials,
            date: try date("2013-05-24T00:00:00Z"))

        #expect(signed.value(forHTTPHeaderField: "x-amz-date") == "20130524T000000Z")
        #expect(
            signed.value(forHTTPHeaderField: "Authorization")
                == "AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request,"
                + "SignedHeaders=host;range;x-amz-content-sha256;x-amz-date,"
                + "Signature=f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41")
    }

    @Test("Matches the AWS test suite get-vanilla signature")
    func matchesGetVanillaVector() throws {
        let signer = SigV4Signer(region: "us-east-1", service: "service")
        let request = URLRequest(url: try #require(URL(string: "https://example.amazonaws.com/")))

        let signed = signer.sign(
            request, payloadHash: Self.emptyPayloadHash,
            credentials: SigningCredentials(
                accessKeyID: "AKIDEXAMPLE", secretAccessKey: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"),
            date: try date("2015-08-30T12:36:00Z"))

        let authorization = try #require(signed.value(forHTTPHeaderField: "Authorization"))
        #expect(authorization.contains("SignedHeaders=host;x-amz-date,"))
        #expect(authorization.hasSuffix("Signature=5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31"))
    }

    @Test("Encodes object key segments exactly once")
    func encodesKeySegmentsOnce() throws {
        let request = URLRequest(url: try #require(URL(string: "https://acc.example.com/bucket/a%20b/c%2Bd.png")))

        let canonical = CanonicalRequest(request: request, payloadHash: Self.emptyPayloadHash)

        #expect(canonical.text.split(separator: "\n").dropFirst().first == "/bucket/a%20b/c%2Bd.png")
    }

    @Test("Includes a non-default port in the host header")
    func includesNonDefaultPort() throws {
        let request = URLRequest(url: try #require(URL(string: "http://localhost:9000/bucket/x.png")))

        let canonical = CanonicalRequest(request: request, payloadHash: Self.emptyPayloadHash)

        #expect(canonical.text.contains("\nhost:localhost:9000\n"))
    }

    private func getObjectRequest() throws -> URLRequest {
        var request = URLRequest(url: try #require(URL(string: "https://examplebucket.s3.amazonaws.com/test.txt")))
        request.setValue("bytes=0-9", forHTTPHeaderField: "Range")
        request.setValue(Self.emptyPayloadHash, forHTTPHeaderField: "x-amz-content-sha256")
        return request
    }

    private func date(_ iso8601: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: iso8601))
    }
}
