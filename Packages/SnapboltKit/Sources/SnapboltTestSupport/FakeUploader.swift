// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation
// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.
import SnapboltCore

/// Returns a canned upload result; when suspends is set, waits for release() first.
public actor FakeUploader: Uploading {
    public private(set) var uploadedImages: [EncodedImage] = []
    private let result: Result<UploadResult, UploadError>
    private let suspends: Bool
    private var waiting: [CheckedContinuation<Void, Never>] = []

    public init(result: Result<UploadResult, UploadError>, suspends: Bool = false) {
        self.result = result
        self.suspends = suspends
    }

    public var waitingCount: Int { waiting.count }

    public func upload(_ image: EncodedImage, using settings: StorageSettings) async throws -> UploadResult {
        uploadedImages.append(image)
        if suspends {
            await withCheckedContinuation { waiting.append($0) }
        }
        return try result.get()
    }

    public func release() {
        waiting.forEach { $0.resume() }
        waiting.removeAll()
    }
}
