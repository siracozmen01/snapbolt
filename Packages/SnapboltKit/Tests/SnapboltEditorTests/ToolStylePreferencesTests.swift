import Foundation
import Testing

@testable import SnapboltEditor

@MainActor
@Suite("Tool style preferences")
struct ToolStylePreferencesTests {
    let defaults = UserDefaults(suiteName: "snapbolt-editor-tests-\(UUID().uuidString)")!

    @Test("Remembers a style per tool")
    func roundTripsPerTool() {
        let preferences = ToolStylePreferences(defaults: defaults)
        var arrow = ToolStyle.standard
        arrow.lineWidthInPoints = 12
        var text = ToolStyle.standard
        text.hasBackground = true

        preferences.save(arrow, for: .arrow)
        preferences.save(text, for: .text)

        #expect(ToolStylePreferences(defaults: defaults).load() == [.arrow: arrow, .text: text])
    }

    @Test("Skips corrupt entries instead of failing")
    func ignoresCorruptEntries() {
        defaults.set(Data("x".utf8), forKey: "editor.style.arrow")

        #expect(ToolStylePreferences(defaults: defaults).load()[.arrow] == nil)
    }
}
