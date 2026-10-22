import Testing

@testable import SnapboltEditor

@Suite("Editor tool")
struct EditorToolTests {
    @Test("Maps each tool to its shortcut key and back", arguments: EditorTool.allCases)
    func mapsShortcutKeys(_ tool: EditorTool) {
        #expect(EditorTool(shortcutKey: tool.shortcutKey) == tool)
    }

    @Test("Keys are V A R T B C")
    func keysMatchSpec() {
        #expect(EditorTool.allCases.map(\.shortcutKey) == ["v", "a", "r", "t", "b", "c"])
        #expect(EditorTool(shortcutKey: "x") == nil)
    }
}
