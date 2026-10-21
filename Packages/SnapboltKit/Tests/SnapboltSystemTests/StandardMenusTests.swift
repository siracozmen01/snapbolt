import AppKit
import Testing

@testable import SnapboltSystem

@MainActor
@Suite("Standard menus")
struct StandardMenusTests {
    struct Shortcut: Sendable, CustomTestStringConvertible {
        let action: String
        let key: String
        let modifiers: NSEvent.ModifierFlags
        var testDescription: String { action }
    }

    nonisolated static let editShortcuts = [
        Shortcut(action: "undo:", key: "z", modifiers: .command),
        Shortcut(action: "redo:", key: "z", modifiers: [.command, .shift]),
        Shortcut(action: "cut:", key: "x", modifiers: .command),
        Shortcut(action: "copy:", key: "c", modifiers: .command),
        Shortcut(action: "paste:", key: "v", modifiers: .command),
        Shortcut(action: "selectAll:", key: "a", modifiers: .command),
    ]

    @Test("The Edit menu provides the text editing shortcuts", arguments: editShortcuts)
    func editMenuProvidesShortcuts(_ shortcut: Shortcut) throws {
        let editMenu = try #require(StandardMenus.makeMainMenu().items.first { $0.title == "Edit" }?.submenu)

        let item = try #require(editMenu.items.first { $0.action == NSSelectorFromString(shortcut.action) })

        #expect(item.keyEquivalent == shortcut.key)
        #expect(item.keyEquivalentModifierMask == shortcut.modifiers)
    }

    @Test("⌘W closes the front window")
    func closeWindowShortcut() throws {
        let items = StandardMenus.makeMainMenu().items.compactMap(\.submenu).flatMap(\.items)

        let close = try #require(items.first { $0.action == #selector(NSWindow.performClose(_:)) })

        #expect(close.keyEquivalent == "w")
    }
}
