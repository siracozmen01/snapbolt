import Foundation
import SnapboltCore
import Testing

@testable import SnapboltSystem

@Suite("Local capture file saver")
struct LocalCaptureFileSaverTests {
    let folder = FileManager.default.temporaryDirectory.appending(path: "snapbolt-captures-\(UUID().uuidString)")
    let image = EncodedImage(data: Data("png-bytes".utf8), contentType: "image/png", fileExtension: "png")
    let capturedAt = ISO8601DateFormatter().date(from: "2026-10-21T14:03:07Z")!
    let saver = LocalCaptureFileSaver(timeZone: .gmt)

    @Test("Saves into a month folder with a timestamped name")
    func savesIntoMonthFolderWithTimestampName() throws {
        let url = try saver.save(image, capturedAt: capturedAt, in: folder)

        #expect(url == folder.appending(path: "2026-10").appending(path: "Snapbolt 2026-10-21 at 14.03.07.png"))
        #expect(try Data(contentsOf: url) == image.data)
    }

    @Test("Never overwrites an existing capture")
    func doesNotOverwriteExistingFile() throws {
        _ = try saver.save(image, capturedAt: capturedAt, in: folder)

        let second = try saver.save(image, capturedAt: capturedAt, in: folder)
        let third = try saver.save(image, capturedAt: capturedAt, in: folder)

        #expect(second.lastPathComponent == "Snapbolt 2026-10-21 at 14.03.07 (2).png")
        #expect(third.lastPathComponent == "Snapbolt 2026-10-21 at 14.03.07 (3).png")
    }

    @Test("Reports a folder that cannot be created")
    func reportsUnwritableFolder() throws {
        try Data().write(to: folder)

        #expect(
            throws: FileSaveError.folderNotWritable(path: folder.appending(path: "2026-10").path(percentEncoded: false))
        ) {
            try saver.save(image, capturedAt: capturedAt, in: folder)
        }
    }
}
