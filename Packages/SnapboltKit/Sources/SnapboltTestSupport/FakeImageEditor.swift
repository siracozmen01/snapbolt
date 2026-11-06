// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation

// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.
import SnapboltCore

/// Returns a stored edit result, or suspends each edit until resumeNext(with:) when suspends is set.
@MainActor
public final class FakeImageEditor: ImageEditing {
    public var result: EditedImage?
    public var suspends = false
    public private(set) var receivedCaptures: [CapturedImage] = []
    private var pending: [CheckedContinuation<EditedImage?, Never>] = []

    public init(result: EditedImage? = nil) {
        self.result = result
    }

    public func edit(_ capture: CapturedImage) async -> EditedImage? {
        receivedCaptures.append(capture)
        guard suspends else { return result }
        return await withCheckedContinuation { pending.append($0) }
    }

    /// Resumes the oldest suspended edit.
    public func resumeNext(with result: EditedImage?) {
        guard !pending.isEmpty else { return }
        pending.removeFirst().resume(returning: result)
    }
}
