// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation
// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.
import Foundation
import SnapboltCore
import Synchronization

/// Records saved captures; can be told to fail.
public final class SpyLocalCaptureSaver: LocalCaptureSaving {
    public struct SavedCapture: Equatable, Sendable {
        public let image: EncodedImage
        public let capturedAt: Date
        public let folder: URL
    }

    private let state = Mutex<[SavedCapture]>([])
    private let failure: FileSaveError?

    public init(failure: FileSaveError? = nil) {
        self.failure = failure
    }

    public var savedCaptures: [SavedCapture] { state.withLock { $0 } }

    public func save(_ image: EncodedImage, capturedAt: Date, in folder: URL) throws -> URL {
        if let failure { throw failure }
        state.withLock { $0.append(SavedCapture(image: image, capturedAt: capturedAt, folder: folder)) }
        return folder.appending(path: "capture.png")
    }
}
