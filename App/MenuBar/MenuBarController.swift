import AppKit
import SnapboltCore

/// The status item and its menu.
@MainActor
final class MenuBarController {
    /// What the menu items do.
    struct Actions {
        let capture: @MainActor (CaptureMode) -> Void
        let copyLink: @MainActor (URL) -> Void
        let openCapturesFolder: @MainActor () -> Void
        let openSettings: @MainActor () -> Void
        let isEditorEnabled: @MainActor () -> Bool
        let toggleEditor: @MainActor () -> Void
    }

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let history: any UploadHistoryStoring
    private let actions: Actions
    private var recentEntries: [HistoryEntry] = []

    init(history: any UploadHistoryStoring, actions: Actions) {
        self.history = history
        self.actions = actions
        statusItem.button?.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Snapbolt")
        rebuildMenu()
    }

    /// Reloads the Recent Uploads submenu from history.
    func refreshRecentUploads() async {
        recentEntries = await history.recentEntries()
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(
            ClosureMenuItem(title: String(localized: "Capture Region or Window")) { [actions] in
                actions.capture(.region)
            })
        menu.addItem(
            ClosureMenuItem(title: String(localized: "Capture Full Screen")) { [actions] in
                actions.capture(.fullScreen)
            })
        menu.addItem(
            ToggleMenuItem(
                title: String(localized: "Edit After Capture"), isOn: actions.isEditorEnabled,
                toggle: actions.toggleEditor))
        menu.addItem(.separator())
        menu.addItem(recentUploadsItem())
        menu.addItem(
            ClosureMenuItem(title: String(localized: "Open Captures Folder"), handler: actions.openCapturesFolder))
        menu.addItem(.separator())
        menu.addItem(
            ClosureMenuItem(title: String(localized: "Settings…"), keyEquivalent: ",", handler: actions.openSettings))
        menu.addItem(
            NSMenuItem(
                title: String(localized: "Quit Snapbolt"), action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func recentUploadsItem() -> NSMenuItem {
        let item = NSMenuItem(title: String(localized: "Recent Uploads"), action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        if recentEntries.isEmpty {
            let empty = NSMenuItem(title: String(localized: "No uploads yet"), action: nil, keyEquivalent: "")
            empty.isEnabled = false
            submenu.addItem(empty)
        }
        let formatter = RelativeDateTimeFormatter()
        for entry in recentEntries {
            let age = formatter.localizedString(for: entry.uploadedAt, relativeTo: .now)
            let title = "\(entry.publicURL.lastPathComponent) — \(age)"
            submenu.addItem(ClosureMenuItem(title: title) { [actions] in actions.copyLink(entry.publicURL) })
        }
        item.submenu = submenu
        return item
    }
}
