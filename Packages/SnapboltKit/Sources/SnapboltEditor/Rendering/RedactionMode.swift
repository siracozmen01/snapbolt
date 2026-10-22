/// How a redaction area hides what is under it.
enum RedactionMode: String, Codable, Sendable {
    /// Large single-colour blocks; the safer choice for sensitive data.
    case pixelate
    /// A Gaussian blur; weak blur can sometimes be reversed.
    case blur
}
