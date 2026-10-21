/// Random, URL-safe tokens that make object keys unguessable.
public enum RandomToken {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")

    /// Returns `length` base62 characters from the system's secure random number generator.
    public static func make(length: Int = 10) -> String {
        var generator = SystemRandomNumberGenerator()
        return String((0..<length).map { _ in alphabet[Int.random(in: 0..<alphabet.count, using: &generator)] })
    }
}
