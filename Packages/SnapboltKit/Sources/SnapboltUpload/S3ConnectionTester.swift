import Foundation
import SnapboltCore

/// Checks storage settings end to end: upload a small object, read it through the public URL, delete it.
public struct S3ConnectionTester: ConnectionTesting {
    private static let unreachableEndpointCodes: Set<URLError.Code> = [
        .cannotFindHost, .cannotConnectToHost, .badURL, .unsupportedURL, .dnsLookupFailed,
    ]

    private let session: URLSession
    private let now: @Sendable () -> Date
    private let randomToken: @Sendable () -> String

    /// Creates a tester. The parameters exist for tests; the defaults are what the app uses.
    public init(
        session: URLSession = .shared,
        now: @escaping @Sendable () -> Date = Date.init,
        randomToken: @escaping @Sendable () -> String = { RandomToken.make() }
    ) {
        self.session = session
        self.now = now
        self.randomToken = randomToken
    }

    /// Uploads, reads back through the public URL and deletes a small test object.
    public func testConnection(using settings: StorageSettings) async -> ConnectionTestOutcome {
        let key = "snapbolt-connection-test-\(randomToken()).txt"
        let client = S3Client(settings: settings, session: session, now: now)
        do {
            try await client.put(
                Data("Snapbolt connection test".utf8), key: key, headers: ["Content-Type": "text/plain"])
        } catch {
            return .failure(Self.failure(for: error))
        }
        let readFailure = await readPublicly(settings.publicURL(forObjectKey: key))
        do {
            try await client.delete(key: key)
        } catch {
            // The test object is tiny and the user has already been told whether the setup works.
            logger.error("Deleting the connection test object failed: \(String(describing: error), privacy: .public)")
        }
        return readFailure.map { .failure($0) } ?? .success
    }

    private func readPublicly(_ url: URL) async -> ConnectionTestFailure? {
        do {
            let (_, response) = try await session.data(from: url)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            return (200..<300).contains(statusCode) ? nil : .publicURLUnreachable(statusCode: statusCode)
        } catch {
            return .publicURLUnreachable(statusCode: nil)
        }
    }

    private static func failure(for error: UploadError) -> ConnectionTestFailure {
        switch error {
        case .network(let code) where unreachableEndpointCodes.contains(code):
            .invalidEndpoint
        case .network(let code):
            .network(code)
        case .invalidEndpoint, .invalidResponse:
            .invalidEndpoint
        case .server(let statusCode, let code, _):
            serverFailure(statusCode: statusCode, code: code)
        }
    }

    private static func serverFailure(statusCode: Int, code: String?) -> ConnectionTestFailure {
        switch code {
        case "InvalidAccessKeyId", "SignatureDoesNotMatch":
            .invalidCredentials
        case "NoSuchBucket":
            .bucketNotFound
        case "AccessDenied":
            .accessDenied
        default:
            .unexpected(statusCode: statusCode, code: code)
        }
    }
}
