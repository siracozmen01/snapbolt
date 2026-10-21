import AppKit

/// The app's main menu. Snapbolt is a menu bar app, so this menu is never shown, but macOS routes
/// keyboard shortcuts such as ⌘V through it: without an Edit menu, text fields cannot paste.
@MainActor
public enum StandardMenus {
    /// Returns a main menu with the app, Edit and Window menus.
    public static func makeMainMenu() -> NSMenu {
        let mainMenu = NSMenu()
        mainMenu.addItem(
            submenu(
                title: "Snapbolt",
                items: [
                    item(String(localized: "Quit Snapbolt"), #selector(NSApplication.terminate(_:)), "q")
                ]))
        mainMenu.addItem(submenu(title: "Edit", items: editItems()))
        mainMenu.addItem(
            submenu(
                title: "Window",
                items: [
                    item(String(localized: "Close"), #selector(NSWindow.performClose(_:)), "w")
                ]))
        return mainMenu
    }

    private static func editItems() -> [NSMenuItem] {
        let redo = item(String(localized: "Redo"), Selector(("redo:")), "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        return [
            item(String(localized: "Undo"), Selector(("undo:")), "z"),
            redo,
            .separator(),
            item(String(localized: "Cut"), #selector(NSText.cut(_:)), "x"),
            item(String(localized: "Copy"), #selector(NSText.copy(_:)), "c"),
            item(String(localized: "Paste"), #selector(NSText.paste(_:)), "v"),
            item(String(localized: "Select All"), #selector(NSText.selectAll(_:)), "a"),
        ]
    }

    private static func submenu(title: String, items: [NSMenuItem]) -> NSMenuItem {
        let menu = NSMenu(title: title)
        items.forEach(menu.addItem)
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    private static func item(_ title: String, _ action: Selector, _ key: String) -> NSMenuItem {
        NSMenuItem(title: title, action: action, keyEquivalent: key)
    }
}
