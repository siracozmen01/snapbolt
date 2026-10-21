import KeyboardShortcuts
import SwiftUI

/// The Shortcuts tab: lets the user record new capture shortcuts.
public struct ShortcutsSettingsView: View {
    /// Creates the tab.
    public init() {}

    /// The view's content.
    public var body: some View {
        Form {
            KeyboardShortcuts.Recorder(String(localized: "Capture Region or Window"), name: .captureRegion)
            KeyboardShortcuts.Recorder(String(localized: "Capture Full Screen"), name: .captureFullScreen)
        }
        .formStyle(.grouped)
    }
}
