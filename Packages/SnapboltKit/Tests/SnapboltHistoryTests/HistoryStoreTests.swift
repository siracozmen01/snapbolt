import Foundation
import SnapboltCore
import Testing

@testable import SnapboltHistory

@Suite("History store")
struct HistoryStoreTests {
    let fileURL = FileManager.default.temporaryDirectory
        .appending(path: "snapbolt-history-\(UUID().uuidString)")
        .appending(path: "history.json")

    func entry(_ index: Int) -> HistoryEntry {
        HistoryEntry(
            publicURL: URL(string: "https://i.example.com/\(index).png")!,
            uploadedAt: Date(timeIntervalSince1970: TimeInterval(index)))
    }

    @Test("Lists the newest upload first")
    func newestFirst() async throws {
        let store = HistoryStore(fileURL: fileURL)

        try await store.add(entry(1))
        try await store.add(entry(2))

        #expect(await store.recentEntries() == [entry(2), entry(1)])
    }

    @Test("Keeps only the ten most recent uploads")
    func keepsOnlyTen() async throws {
        let store = HistoryStore(fileURL: fileURL)

        for index in 1...12 {
            try await store.add(entry(index))
        }

        #expect(await store.recentEntries() == (3...12).reversed().map(entry))
    }

    @Test("Persists across instances")
    func persistsAcrossInstances() async throws {
        try await HistoryStore(fileURL: fileURL).add(entry(1))

        #expect(await HistoryStore(fileURL: fileURL).recentEntries() == [entry(1)])
    }

    @Test("A missing file means no history")
    func missingFileMeansEmpty() async {
        #expect(await HistoryStore(fileURL: fileURL).recentEntries().isEmpty)
    }

    @Test("A corrupt file means no history and is replaced on the next upload")
    func corruptFileMeansEmptyAndIsReplacedOnAdd() async throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: fileURL)
        let store = HistoryStore(fileURL: fileURL)

        #expect(await store.recentEntries().isEmpty)
        try await store.add(entry(1))

        #expect(await HistoryStore(fileURL: fileURL).recentEntries() == [entry(1)])
    }
}
