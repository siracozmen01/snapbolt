import CoreGraphics
import SnapboltCore
import SnapboltTestSupport

@testable import SnapboltEditor

/// Returns a fixed 7×5 image, or fails with `.exportFailed`.
struct FakeExporter: DocumentExporting {
    var fails = false

    func export(_ document: AnnotationDocument) throws(EditorError) -> CGImage {
        if fails { throw .exportFailed }
        return .solid(width: 7, height: 5)
    }
}

/// Records what an editor model finished with.
@MainActor
final class FinishRecorder {
    private(set) var results: [EditedImage?] = []

    func record(_ result: EditedImage?) {
        results.append(result)
    }
}
