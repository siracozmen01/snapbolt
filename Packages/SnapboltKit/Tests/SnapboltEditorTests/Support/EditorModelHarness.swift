import CoreGraphics
import Foundation
import SnapboltCore
import SnapboltTestSupport

@testable import SnapboltEditor

/// An editor model on a 200×100 px capture with a fake exporter, plus gesture helpers.
@MainActor
struct EditorModelHarness {
    let recorder = FinishRecorder()
    let defaults = UserDefaults(suiteName: "snapbolt-editor-model-tests-\(UUID().uuidString)")!
    let model: EditorModel

    init(scale: CGFloat = 1, failingExport: Bool = false) {
        model = EditorModel(
            capture: CapturedImage(image: .solid(width: 200, height: 100), scale: scale),
            preferences: ToolStylePreferences(defaults: defaults), exporter: FakeExporter(fails: failingExport),
            onFinish: { [recorder] in recorder.record($0) })
    }

    /// The one result the model finished with, or `nil` if it finished without one or has not finished.
    var finishedImage: EditedImage? { recorder.results.first.flatMap { $0 } }

    func drag(from: CGPoint, to: CGPoint, steps: Int = 1) {
        model.pointerDown(atCanvas: from, isShiftDown: false, clickCount: 1)
        for step in 1...steps {
            let fraction = CGFloat(step) / CGFloat(steps)
            let point = CGPoint(x: from.x + (to.x - from.x) * fraction, y: from.y + (to.y - from.y) * fraction)
            model.pointerDragged(toCanvas: point, isShiftDown: false)
        }
        model.pointerUp(atCanvas: to, isShiftDown: false)
    }

    func drawRectangle() {
        model.selectTool(.rectangle)
        drag(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 60, y: 40))
    }

    func placeText(_ string: String, at point: CGPoint = CGPoint(x: 20, y: 20)) {
        model.selectTool(.text)
        drag(from: point, to: point)
        model.commitText(string)
    }
}
