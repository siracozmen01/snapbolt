import ServiceManagement
import SnapboltCore

/// Registers Snapbolt as a login item.
@MainActor
public final class LaunchAtLoginController: LaunchAtLoginControlling {
    /// Creates a controller for the main app.
    public init() {}

    /// Whether Snapbolt is registered to launch at login.
    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Registers or unregisters the login item.
    public func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
