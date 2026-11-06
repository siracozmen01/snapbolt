import AppKit
import Observation
import SnapboltCore
import SwiftUI

/// Owns one editor window: the toolbar, the zoomable canvas, the confirmation sheets and closing.
@MainActor
final class EditorWindowController: NSObject, NSWindowDelegate {
    private let model: EditorModel
    private let window: NSWindow
    private let scrollView = NSScrollView()
    private var canvas: EditorCanvasView?

    init(model: EditorModel, renderer: AnnotationRenderer, layout: EditorWindowLayout) {
        self.model = model
        window = NSWindow(
            contentRect: CGRect(origin: .zero, size: layout.contentSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init()
        let canvas = EditorCanvasView(
            model: model, renderer: renderer, onZoom: { [weak self] in self?.zoom($0) },
            onFinish: { [weak self] in self?.finish($0) })
        self.canvas = canvas
        configureWindow()
        configureScrollView(canvas: canvas, magnification: layout.magnification)
        layOutContent()
        observePhase()
    }

    /// The screen under the mouse, where the editor opens.
    static var screenUnderMouse: NSScreen? {
        NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
    }

    /// Centres the window on the screen under the mouse and brings it to the front, also over full-screen apps.
    func show() {
        if let visible = Self.screenUnderMouse?.visibleFrame {
            let size = window.frame.size
            window.setFrameOrigin(CGPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2))
        }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(canvas)
    }

    func close() {
        window.orderOut(nil)
        window.close()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        cancel()
        return false
    }

    private func configureWindow() {
        window.title = String(localized: "Snapbolt Editor")
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
        window.delegate = self
    }

    private func configureScrollView(canvas: EditorCanvasView, magnification: CGFloat) {
        scrollView.documentView = canvas
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.allowsMagnification = true
        scrollView.minMagnification = ZoomLevels.minimum
        scrollView.maxMagnification = ZoomLevels.maximum
        scrollView.magnification = magnification
        scrollView.backgroundColor = .underPageBackgroundColor
        model.setMagnification(magnification)
        NotificationCenter.default.addObserver(
            self, selector: #selector(scrollViewDidMagnify), name: NSScrollView.didEndLiveMagnifyNotification,
            object: scrollView)
    }

    private func layOutContent() {
        let toolbar = NSHostingView(
            rootView: EditorToolbarView(
                model: model, onZoom: { [weak self] in self?.zoom($0) }, onFinish: { [weak self] in self?.finish($0) },
                onCancel: { [weak self] in self?.cancel() }))
        let stack = NSStackView(views: [toolbar, scrollView])
        stack.orientation = .vertical
        stack.spacing = 0
        stack.setHuggingPriority(.defaultLow, for: .vertical)
        toolbar.heightAnchor.constraint(equalToConstant: EditorWindowLayout.toolbarHeight).isActive = true
        window.contentView = stack
    }

    @objc private func scrollViewDidMagnify() {
        model.setMagnification(scrollView.magnification)
    }

    private func zoom(_ command: ZoomCommand) {
        let current = scrollView.magnification
        let target: CGFloat
        switch command {
        case .zoomIn: target = ZoomLevels.zoomedIn(from: current)
        case .zoomOut: target = ZoomLevels.zoomedOut(from: current)
        case .actualSize: target = 1
        case .magnification(let value): target = value
        case .fit: target = ZoomLevels.fitting(canvas?.frame.size ?? .zero, in: scrollView.contentSize)
        }
        scrollView.animator().magnification = target
        model.setMagnification(target)
    }

    private func finish(_ destination: EditedImage.Destination) {
        canvas?.commitTextEditing()
        Task { await model.finish(destination) }
    }

    private func cancel() {
        canvas?.commitTextEditing()
        model.cancel()
    }

    private func observePhase() {
        withObservationTracking {
            _ = model.phase
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.phaseDidChange()
                self?.observePhase()
            }
        }
    }

    private func phaseDidChange() {
        switch model.phase {
        case .confirmingDiscard: askToDiscard()
        case .exportFailed: reportExportFailure()
        case .finished: close()
        case .editing, .exporting: break
        }
    }

    private func askToDiscard() {
        let alert = NSAlert()
        alert.messageText = String(localized: "Discard this capture?")
        alert.addButton(withTitle: String(localized: "Discard"))
        alert.addButton(withTitle: String(localized: "Keep Editing"))
        alert.beginSheetModal(for: window) { [weak self] response in
            if response == .alertFirstButtonReturn {
                self?.model.confirmDiscard()
            } else {
                self?.model.keepEditing()
            }
        }
    }

    private func reportExportFailure() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = String(localized: "Could not export the edited image.")
        alert.beginSheetModal(for: window) { [weak self] _ in self?.model.dismissExportError() }
    }
}
