import Foundation

/// A validated pattern for object keys, e.g. `{yyyy}/{MM}/{random}`.
///
/// `{random}` is required so that keys are unguessable and never overwrite each other, which is
/// what allows uploads to be served with an immutable cache policy.
public struct ObjectKeyTemplate: Equatable, Sendable {
    /// Why a template was rejected.
    public enum ValidationError: Error, Equatable, Sendable {
        /// The template is empty.
        case empty
        /// The template has no `{random}` token.
        case missingRandomToken
        /// The template contains a token Snapbolt does not know.
        case unknownToken(String)
    }

    /// `{yyyy}/{MM}/{random}`.
    public static let defaultTemplate = ObjectKeyTemplate(unchecked: "{yyyy}/{MM}/{random}")

    private static let randomToken = "{random}"
    private static let dateTokens: [String: @Sendable (DateComponents) -> Int?] = [
        "{yyyy}": { $0.year }, "{MM}": { $0.month }, "{dd}": { $0.day },
        "{HH}": { $0.hour }, "{mm}": { $0.minute }, "{ss}": { $0.second },
    ]

    /// The template as the user wrote it.
    public let rawValue: String

    /// Validates `raw` and creates a template.
    public init(validating raw: String) throws(ValidationError) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw .empty }
        for token in Self.tokens(in: trimmed) where token != Self.randomToken && Self.dateTokens[token] == nil {
            throw .unknownToken(token)
        }
        guard trimmed.contains(Self.randomToken) else { throw .missingRandomToken }
        self.init(unchecked: trimmed)
    }

    private init(unchecked rawValue: String) {
        self.rawValue = rawValue
    }

    /// Expands the template for `date` in `timeZone` and appends `.fileExtension`.
    public func objectKey(date: Date, random: String, fileExtension: String, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        var key = rawValue.replacingOccurrences(of: Self.randomToken, with: random)
        for (token, value) in Self.dateTokens {
            let width = token == "{yyyy}" ? 4 : 2
            key = key.replacingOccurrences(of: token, with: Self.zeroPadded(value(components) ?? 0, width: width))
        }
        return key + "." + fileExtension
    }

    private static func tokens(in template: String) -> [String] {
        template.matches(of: /\{[^}]*\}/).map { String(template[$0.range]) }
    }

    private static func zeroPadded(_ value: Int, width: Int) -> String {
        let digits = String(value)
        return String(repeating: "0", count: max(0, width - digits.count)) + digits
    }
}
