import Foundation
import SnapboltCore
import SnapboltTestSupport
import Testing

@testable import SnapboltUpload

@Suite("S3 connection tester")
struct S3ConnectionTesterTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let responses: [StubServer.Response]
        let expected: ConnectionTestFailure
        var testDescription: String { "\(expected)" }
    }

    static func errorBody(_ code: String) -> String {
        "<Error><Code>\(code)</Code><Message>m</Message></Error>"
    }

    static let failureCases: [Case] = [
        Case(responses: [.failure(.cannotFindHost)], expected: .invalidEndpoint),
        Case(responses: [.failure(.cannotConnectToHost)], expected: .invalidEndpoint),
        Case(responses: [.failure(.timedOut)], expected: .network(.timedOut)),
        Case(responses: [.status(403, body: errorBody("InvalidAccessKeyId"))], expected: .invalidCredentials),
        Case(responses: [.status(403, body: errorBody("SignatureDoesNotMatch"))], expected: .invalidCredentials),
        Case(responses: [.status(404, body: errorBody("NoSuchBucket"))], expected: .bucketNotFound),
        Case(responses: [.status(403, body: errorBody("AccessDenied"))], expected: .accessDenied),
        Case(
            responses: [.status(500, body: errorBody("InternalError"))],
            expected: .unexpected(statusCode: 500, code: "InternalError")),
        Case(responses: [.status(200), .status(404), .status(204)], expected: .publicURLUnreachable(statusCode: 404)),
        Case(
            responses: [.status(200), .failure(.cannotFindHost), .status(204)],
            expected: .publicURLUnreachable(statusCode: nil)),
    ]

    func makeTester(_ server: StubServer) -> S3ConnectionTester {
        S3ConnectionTester(session: server.session, now: Date.init, randomToken: { "tok" })
    }

    @Test("Succeeds when upload, public read and delete work, in that order")
    func succeedsWhenAllStepsWork() async {
        let server = StubServer([.status(200), .status(200), .status(204)])

        let outcome = await makeTester(server).testConnection(using: .fixture())

        #expect(outcome == .success)
        #expect(server.requests.map(\.method) == ["PUT", "GET", "DELETE"])
        #expect(
            server.requests.map(\.url.absoluteString) == [
                "https://acc.r2.cloudflarestorage.com/shots/snapbolt-connection-test-tok.txt",
                "https://i.example.com/snapbolt-connection-test-tok.txt",
                "https://acc.r2.cloudflarestorage.com/shots/snapbolt-connection-test-tok.txt",
            ])
        #expect(server.requests[1].header("Authorization") == nil)
    }

    @Test("Maps each failure to a specific reason", arguments: failureCases)
    func mapsFailure(_ testCase: Case) async {
        let outcome = await makeTester(StubServer(testCase.responses)).testConnection(using: .fixture())

        #expect(outcome == .failure(testCase.expected))
    }

    @Test("Deletes the test object even when the public URL fails")
    func deletesEvenWhenPublicURLFails() async {
        let server = StubServer([.status(200), .status(403), .status(204)])

        _ = await makeTester(server).testConnection(using: .fixture())

        #expect(server.requests.map(\.method) == ["PUT", "GET", "DELETE"])
    }

    @Test("Does not delete when the upload failed")
    func skipsDeleteWhenUploadFailed() async {
        let server = StubServer([.status(403, body: Self.errorBody("AccessDenied"))])

        _ = await makeTester(server).testConnection(using: .fixture())

        #expect(server.requests.map(\.method) == ["PUT"])
    }
}
