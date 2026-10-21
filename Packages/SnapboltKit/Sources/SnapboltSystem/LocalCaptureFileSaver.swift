import Foundation
import SnapboltCore

/// Writes local copies to `<folder>/YYYY-MM/Snapbolt YYYY-MM-DD at HH.mm.ss.<ext>`, never overwriting.
public struct LocalCaptureFileSaver: LocalCaptureSaving {
    private let timeZone: TimeZone

    /// Creates a saver that names files in `timeZone`.
    public init(timeZone: TimeZone = .current) {
        self.timeZone = timeZone
    }

    /// Saves `image` and returns the file URL.
    /// - Throws: ``FileSaveError``.
    public func save(_ image: EncodedImage, capturedAt: Date, in folder: URL) throws -> URL {
        let stamp = Timestamp(capturedAt, timeZone: timeZone)
        let monthFolder = folder.appending(path: stamp.month)
        do {
            try FileManager.default.createDirectory(at: monthFolder, withIntermediateDirectories: true)
        } catch {
            throw FileSaveError.folderNotWritable(path: monthFolder.path(percentEncoded: false))
        }
        let url = Self.unusedURL(
            in: monthFolder, baseName: "Snapbolt \(stamp.day) at \(stamp.time)", ext: image.fileExtension)
        do {
            try image.data.write(to: url, options: .withoutOverwriting)
        } catch {
            throw FileSaveError.writeFailed(path: url.path(percentEncoded: false))
        }
        return url
    }

    private static func unusedURL(in folder: URL, baseName: String, ext: String) -> URL {
        var candidate = folder.appending(path: "\(baseName).\(ext)")
        var number = 2
        while FileManager.default.fileExists(atPath: candidate.path(percentEncoded: false)) {
            candidate = folder.appending(path: "\(baseName) (\(number)).\(ext)")
            number += 1
        }
        return candidate
    }
}

/// The parts of a capture date used in folder and file names.
private struct Timestamp {
    /// `YYYY-MM`
    let month: String
    /// `YYYY-MM-DD`
    let day: String
    /// `HH.mm.ss`
    let time: String

    init(_ date: Date, timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        func two(_ value: Int?) -> String { String(format: "%02d", value ?? 0) }
        month = String(format: "%04d", parts.year ?? 0) + "-" + two(parts.month)
        day = month + "-" + two(parts.day)
        time = [parts.hour, parts.minute, parts.second].map(two).joined(separator: ".")
    }
}
