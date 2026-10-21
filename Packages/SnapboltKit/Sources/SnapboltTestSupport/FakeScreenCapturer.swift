// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation
// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.
import SnapboltCore

/// Returns canned frozen screens and records the requested scopes.
public actor FakeScreenCapturer: ScreenCapturing {
    public private(set) var requestedScopes: [CaptureScope] = []
    private let result: Result<FrozenScreens, CaptureError>

    public init(result: Result<FrozenScreens, CaptureError>) {
        self.result = result
    }

    public func freezeDisplays(_ scope: CaptureScope) async throws -> FrozenScreens {
        requestedScopes.append(scope)
        return try result.get()
    }
}
