/// Turns launching at login on and off.
@MainActor
public protocol LaunchAtLoginControlling {
    /// Whether Snapbolt is registered to launch at login.
    var isEnabled: Bool { get }
    /// Registers or unregisters launching at login.
    func setEnabled(_ enabled: Bool) throws
}
