import SnapboltCore

/// How often and how long to wait before retrying a failed request.
struct RetryPolicy: Sendable {
    /// Two retries after 1 s and 2 s.
    static let standard = RetryPolicy(delays: [.seconds(1), .seconds(2)])

    /// The wait before each retry; the number of retries is `delays.count`.
    let delays: [Duration]

    /// Runs `operation`, retrying network errors and HTTP 5xx. Client errors (4xx) are thrown at once
    /// because retrying cannot fix them.
    func run<Value>(
        sleep: @Sendable (Duration) async throws -> Void,
        _ operation: () async throws(UploadError) -> Value
    ) async throws -> Value {
        for delay in delays {
            do {
                return try await operation()
            } catch {
                // Not `catch where`: Swift 6.3 crashes compiling that form here (MandatoryAllocBoxToStack).
                guard Self.isRetryable(error) else { throw error }
            }
            try Task.checkCancellation()
            try await sleep(delay)
        }
        return try await operation()
    }

    private static func isRetryable(_ error: UploadError) -> Bool {
        switch error {
        case .network:
            true
        case .server(let statusCode, _, _):
            statusCode >= 500
        case .invalidEndpoint, .invalidResponse:
            false
        }
    }
}
