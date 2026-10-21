import Foundation
import SnapboltCore

/// Uploads encoded images to an S3-compatible bucket (Cloudflare R2, AWS S3, MinIO).
///
/// Objects get an immutable cache policy because keys contain a random token and are never reused.
public final class S3Uploader: Uploading {
    private static let cacheControl = "public, max-age=31536000, immutable"

    private let session: URLSession
    private let now: @Sendable () -> Date
    private let randomToken: @Sendable () -> String
    private let sleep: @Sendable (Duration) async throws -> Void
    private let timeZone: TimeZone
    private let retryPolicy = RetryPolicy.standard

    /// Creates an uploader. The parameters exist for tests; the defaults are what the app uses.
    public init(
        session: URLSession = .shared,
        now: @escaping @Sendable () -> Date = Date.init,
        randomToken: @escaping @Sendable () -> String = { RandomToken.make() },
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
        timeZone: TimeZone = .current
    ) {
        self.session = session
        self.now = now
        self.randomToken = randomToken
        self.sleep = sleep
        self.timeZone = timeZone
    }

    /// Uploads `image` and returns its object key and public URL.
    ///
    /// Retries network errors and HTTP 5xx up to two times; client errors are reported at once.
    public func upload(_ image: EncodedImage, using settings: StorageSettings) async throws -> UploadResult {
        let key = settings.keyTemplate.objectKey(
            date: now(), random: randomToken(), fileExtension: image.fileExtension, timeZone: timeZone)
        let client = S3Client(settings: settings, session: session, now: now)
        let headers = ["Content-Type": image.contentType, "Cache-Control": Self.cacheControl]
        try await retryPolicy.run(sleep: sleep) { () async throws(UploadError) in
            try await client.put(image.data, key: key, headers: headers)
        }
        logger.info("Uploaded \(key, privacy: .private)")
        return UploadResult(objectKey: key, publicURL: settings.publicURL(forObjectKey: key))
    }
}
