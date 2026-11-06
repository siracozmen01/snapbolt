import SnapboltCore
import SwiftUI

/// The toolbar above the canvas: tools, style, undo, zoom and the three ways out.
struct EditorToolbarView: View {
    let model: EditorModel
    let onZoom: @MainActor (ZoomCommand) -> Void
    let onFinish: @MainActor (EditedImage.Destination) -> Void
    let onCancel: @MainActor () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ToolPickerView(model: model)
            StyleControlsView(model: model)
            Spacer(minLength: 8)
            undoButtons
            zoomMenu
            exitButtons
        }
        .padding(.horizontal, 12)
        .frame(height: EditorWindowLayout.toolbarHeight)
        .disabled(model.phase != .editing)
    }

    private var undoButtons: some View {
        HStack(spacing: 4) {
            Button {
                model.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .help(String(localized: "Undo (⌘Z)"))
            .disabled(!model.canUndo)
            Button {
                model.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .help(String(localized: "Redo (⇧⌘Z)"))
            .disabled(!model.canRedo)
        }
        .buttonStyle(.borderless)
    }

    private var zoomMenu: some View {
        Menu("\(Int((model.mapping.magnification * 100).rounded()))%") {
            Button(String(localized: "Fit")) { onZoom(.fit) }
            Button("50%") { onZoom(.magnification(0.5)) }
            Button("100%") { onZoom(.actualSize) }
            Button("200%") { onZoom(.magnification(2)) }
        }
        .fixedSize()
    }

    private var exitButtons: some View {
        HStack(spacing: 8) {
            if model.phase == .exporting {
                ProgressView().controlSize(.small)
            }
            Button(String(localized: "Cancel")) { onCancel() }
                .help(String(localized: "Discard this capture (Escape)"))
            Button(String(localized: "Copy")) { onFinish(.clipboard) }
                .help(String(localized: "Copy the image without uploading (⇧⌘C)"))
            Button(String(localized: "Upload")) { onFinish(.upload) }
                .buttonStyle(.borderedProminent)
                .help(String(localized: "Upload and copy the link (⌘Return)"))
        }
    }
}
