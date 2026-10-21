import Foundation
import Testing

@testable import SnapboltCore

@Suite("Object key template")
struct ObjectKeyTemplateTests {
    @Test("Expands every date token and the random token")
    func expandsTokens() throws {
        let template = try ObjectKeyTemplate(validating: "{yyyy}/{MM}/{dd}/{HH}{mm}{ss}-{random}")

        let key = template.objectKey(
            date: try date("2026-10-21T09:05:07Z"),
            random: "abc",
            fileExtension: "png",
            timeZone: .gmt
        )

        #expect(key == "2026/10/21/090507-abc.png")
    }

    @Test("Expands dates in the given time zone")
    func usesGivenTimeZone() throws {
        let istanbul = try #require(TimeZone(identifier: "Europe/Istanbul"))

        let key = ObjectKeyTemplate.defaultTemplate.objectKey(
            date: try date("2026-12-31T22:30:00Z"),
            random: "r",
            fileExtension: "png",
            timeZone: istanbul
        )

        #expect(key == "2027/01/r.png")
    }

    @Test("Default template is year/month/random")
    func defaultTemplate() {
        #expect(ObjectKeyTemplate.defaultTemplate.rawValue == "{yyyy}/{MM}/{random}")
    }

    @Test("Rejects an empty template")
    func rejectsEmpty() {
        #expect(throws: ObjectKeyTemplate.ValidationError.empty) {
            try ObjectKeyTemplate(validating: "  ")
        }
    }

    @Test("Rejects templates without a random token")
    func rejectsTemplatesWithoutRandom() {
        #expect(throws: ObjectKeyTemplate.ValidationError.missingRandomToken) {
            try ObjectKeyTemplate(validating: "{yyyy}/{MM}")
        }
    }

    @Test("Rejects unknown tokens")
    func rejectsUnknownToken() {
        #expect(throws: ObjectKeyTemplate.ValidationError.unknownToken("{foo}")) {
            try ObjectKeyTemplate(validating: "{foo}/{random}")
        }
    }

    private func date(_ iso8601: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: iso8601))
    }
}
