import KeyboardShortcuts
import Testing

@testable import SnapboltHotkeys

@Suite("Shortcut names")
struct ShortcutNamesTests {
    @Test("Default shortcuts match the spec: ⌥⇧4 and ⌥⇧3")
    func defaultShortcutsMatchSpec() {
        #expect(KeyboardShortcuts.Name.captureRegion.initialShortcut == .init(.four, modifiers: [.option, .shift]))
        #expect(
            KeyboardShortcuts.Name.captureFullScreen.initialShortcut == .init(.three, modifiers: [.option, .shift]))
    }
}
