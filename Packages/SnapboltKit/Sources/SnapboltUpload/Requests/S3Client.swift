import Foundation
import SnapboltCore

/// Signed object requests against one bucket, using path-style URLs (`{endpoint}/{bucket}/{key}`)
/// so the same code works with Cloudflare R2, AWS S3 and MinIO.
struct S3Client: Sendable {
    private let settings: StorageSettings
    private let session: URLSession
    private let now: @Sendable () -> Date
    private let signer: SigV4Signer

    init(settings: StorageSettings, session: URLSession, now: @escaping @Sendable () -> Date) {
        self.settings = settings
        self.session = session
        self.now = now
        signer = SigV4Signer(region: settings.region, service: "s3")
    }

    /// Uploads `data` to `key` with the given extra headers.
    func put(_ data: Data, key: String, headers: [String: String]) async throws(UploadError) {
        var request = URLRequest(url: try objectURL(for: key))
        request.httpMethod = "PUT"
        request.httpBody = data
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        try await send(request, payload: data)
    }

    /// Deletes `key`.
    func delete(key: String) async throws(UploadError) {
        var request = URLRequest(url: try objectURL(for: key))
        request.httpMethod = "DELETE"
        try await send(request, payload: Data())
    }

    private func objectURL(for key: String) throws(UploadError) -> URL {
        var endpoint = settings.endpoint.absoluteString
        while endpoint.hasSuffix("/") {
            endpoint.removeLast()
        }
        let path = ([settings.bucket] + key.split(separator: "/", omittingEmptySubsequences: false).map(String.init))
            .map(ObjectKeyEncoding.percentEncodedSegment)
            .joined(separator: "/")
        guard let url = URL(string: "\(endpoint)/\(path)"), url.host() != nil else {
            throw .invalidEndpoint(settings.endpoint.absoluteString)
        }
        return url
    }

    private func send(_ request: URLRequest, payload: Data) async throws(UploadError) {
        var request = request
        let payloadHash = SigV4Signer.hexSHA256(payload)
        request.setValue(payloadHash, forHTTPHeaderField: "x-amz-content-sha256")
        let credentials = SigningCredentials(
            accessKeyID: settings.accessKeyID, secretAccessKey: settings.secretAccessKey)
        let signed = signer.sign(request, payloadHash: payloadHash, credentials: credentials, date: now())
        let (body, response) = try await data(for: signed)
        guard let http = response as? HTTPURLResponse else { throw .invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let error = S3ErrorResponse.parse(body)
            throw .server(statusCode: http.statusCode, code: error.code, message: error.message)
        }
    }

    private func data(for request: URLRequest) async throws(UploadError) -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            throw .network(error.code)
        } catch {
            throw .network(.unknown)
        }
    }
}
