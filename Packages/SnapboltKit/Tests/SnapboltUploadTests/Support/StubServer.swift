import Foundation
import Synchronization

/// A fake HTTP server behind its own `URLSession`. Requests are routed by a per-server header, so
/// tests using different servers can run in parallel.
final class StubServer: Sendable {
    enum Response: Sendable {
        case status(Int, body: String = "")
        case failure(URLError.Code)
    }

    struct RecordedRequest: Sendable {
        let method: String
        let url: URL
        let headers: [String: String]
        let body: Data

        func header(_ name: String) -> String? {
            headers.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
        }
    }

    static let routingHeader = "X-Stub-Server"

    let session: URLSession
    private let id = UUID().uuidString
    private let state: Mutex<(queue: [Response], requests: [RecordedRequest])>

    /// Answers requests with `responses` in order; the last one repeats.
    init(_ responses: [Response]) {
        state = Mutex((queue: responses, requests: []))
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        configuration.httpAdditionalHeaders = [Self.routingHeader: id]
        session = URLSession(configuration: configuration)
        StubURLProtocol.register(self, id: id)
    }

    var requests: [RecordedRequest] { state.withLock { $0.requests } }

    func respond(to request: RecordedRequest) -> Response {
        state.withLock { state in
            state.requests.append(request)
            return state.queue.count > 1 ? state.queue.removeFirst() : state.queue.first ?? .status(200)
        }
    }
}

final class StubURLProtocol: URLProtocol {
    private static let servers = Mutex<[String: StubServer]>([:])

    static func register(_ server: StubServer, id: String) {
        servers.withLock { $0[id] = server }
    }

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        guard
            let url = request.url,
            let id = request.value(forHTTPHeaderField: StubServer.routingHeader),
            let server = Self.servers.withLock({ $0[id] })
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        let recorded = StubServer.RecordedRequest(
            method: request.httpMethod ?? "GET", url: url, headers: request.allHTTPHeaderFields ?? [:],
            body: bodyData())
        switch server.respond(to: recorded) {
        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        case .status(let status, let body):
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)
            if let response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    // URLSession moves `httpBody` into a stream before handing the request to a protocol.
    private func bodyData() -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

/// Records requested sleeps instead of sleeping.
actor SleepRecorder {
    private(set) var durations: [Duration] = []

    func sleep(_ duration: Duration) {
        durations.append(duration)
    }
}
