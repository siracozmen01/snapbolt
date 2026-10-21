// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation
// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.
import SnapboltCore

/// Returns a canned connection test outcome and records the tested settings.
public actor FakeConnectionTester: ConnectionTesting {
    public private(set) var testedSettings: [StorageSettings] = []
    private let outcome: ConnectionTestOutcome

    public init(outcome: ConnectionTestOutcome) {
        self.outcome = outcome
    }

    public func testConnection(using settings: StorageSettings) async -> ConnectionTestOutcome {
        testedSettings.append(settings)
        return outcome
    }
}
