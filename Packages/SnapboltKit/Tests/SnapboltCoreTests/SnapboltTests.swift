import Testing

@testable import SnapboltCore

@Test func bundleIdentifierMatchesTheApp() {
    #expect(Snapbolt.bundleIdentifier == "io.github.siracozmen01.Snapbolt")
}
