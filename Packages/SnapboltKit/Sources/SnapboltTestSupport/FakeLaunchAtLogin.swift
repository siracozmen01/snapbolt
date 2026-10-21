// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation
// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.
import SnapboltCore

/// In-memory launch-at-login switch that can be told to fail.
@MainActor
public final class FakeLaunchAtLogin: LaunchAtLoginControlling {
    public struct Failure: Error {}

    public private(set) var isEnabled = false
    public var failsOnChange = false

    public init() {}

    public func setEnabled(_ enabled: Bool) throws {
        if failsOnChange { throw Failure() }
        isEnabled = enabled
    }
}
