import Testing

@testable import SnapboltCore

@Suite("Random token")
struct RandomTokenTests {
    @Test("Produces base62 tokens of the requested length")
    func producesBase62TokensOfRequestedLength() {
        let base62 = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")

        let tokens = (0..<100).map { _ in RandomToken.make() }

        #expect(tokens.allSatisfy { $0.count == 10 })
        #expect(tokens.allSatisfy { $0.allSatisfy(base62.contains) })
        #expect(Set(tokens).count > 1)
        #expect(RandomToken.make(length: 4).count == 4)
    }
}
