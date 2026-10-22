import Foundation
import Testing

@testable import SnapboltCore

@Suite("Capture preferences")
struct CapturePreferencesTests {
    @Test("The editor is off unless asked for")
    func editorIsOffByDefault() {
        let preferences = CapturePreferences(saveLocally: true, folder: URL(filePath: "/captures"))

        #expect(!preferences.opensEditor)
    }
}
