import Observation
import SnapboltHotkeys
import SnapboltSettings
import SwiftUI

/// The settings window's tabs.
enum SettingsTab: Hashable {
    case storage
    case general
    case shortcuts
}

/// Which settings tab is shown; lets other parts of the app open a specific tab.
@MainActor
@Observable
final class SettingsNavigation {
    var tab = SettingsTab.storage
}

/// Assembles the panes that each module provides into one window.
struct SettingsRootView: View {
    @Bindable var navigation: SettingsNavigation
    let storage: StorageSettingsModel
    let general: GeneralSettingsModel

    var body: some View {
        TabView(selection: $navigation.tab) {
            StorageSettingsView(model: storage)
                .tabItem { Label("Storage", systemImage: "externaldrive.connected.to.line.below") }
                .tag(SettingsTab.storage)
            GeneralSettingsView(model: general)
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(SettingsTab.general)
            ShortcutsSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
                .tag(SettingsTab.shortcuts)
        }
        .frame(width: 560, height: 520)
    }
}
