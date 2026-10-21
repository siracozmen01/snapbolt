// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation

// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.
import SnapboltCore
import Synchronization

/// Reports a configurable permission state and counts requests.
public final class FakePermissionChecker: PermissionChecking {
    private struct State {
        var granted: Bool
        var screenRecordingRequests = 0
        var settingsOpened = 0
    }

    private let state: Mutex<State>
    private let notificationsGranted: Bool

    public init(granted: Bool, notificationsGranted: Bool = true) {
        state = Mutex(State(granted: granted))
        self.notificationsGranted = notificationsGranted
    }

    public var screenRecordingRequests: Int { state.withLock { $0.screenRecordingRequests } }
    public var settingsOpened: Int { state.withLock { $0.settingsOpened } }

    public func setGranted(_ granted: Bool) {
        state.withLock { $0.granted = granted }
    }

    public func hasScreenRecordingPermission() -> Bool {
        state.withLock { $0.granted }
    }

    public func requestScreenRecordingPermission() {
        state.withLock { $0.screenRecordingRequests += 1 }
    }

    public func openScreenRecordingSettings() {
        state.withLock { $0.settingsOpened += 1 }
    }

    public func requestNotificationPermission() async -> Bool {
        notificationsGranted
    }
}
