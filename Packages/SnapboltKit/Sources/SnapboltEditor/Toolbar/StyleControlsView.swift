import SwiftUI

/// The style controls of the active tool, or of the selected shape.
struct StyleControlsView: View {
    let model: EditorModel
    @State private var strength: Double?

    var body: some View {
        HStack(spacing: 10) {
            switch model.styleTool {
            case .arrow:
                colorPicker
                number(String(localized: "Width"), \.lineWidthInPoints, in: ToolStyle.lineWidthRangeInPoints)
            case .rectangle:
                colorPicker
                number(String(localized: "Width"), \.lineWidthInPoints, in: ToolStyle.lineWidthRangeInPoints)
                Toggle(String(localized: "Filled"), isOn: style.isFilled)
            case .text:
                colorPicker
                number(String(localized: "Size"), \.fontSizeInPoints, in: ToolStyle.fontSizeRangeInPoints)
                Toggle(String(localized: "Background"), isOn: style.hasBackground)
            case .redaction:
                redactionControls
            case .crop:
                cropControls
            case .select:
                EmptyView()
            }
        }
        .controlSize(.small)
    }

    private var style: Binding<ToolStyle> {
        Binding(get: { model.currentStyle }, set: { model.applyStyle($0) })
    }

    private var colorPicker: some View {
        ColorPicker(
            String(localized: "Colour"),
            selection: Binding(
                get: { model.currentStyle.color.cgColor },
                set: { color in
                    guard let rgba = RGBAColor(cgColor: color) else { return }
                    style.wrappedValue.color = rgba
                }),
            supportsOpacity: true
        )
        .labelsHidden()
    }

    private var redactionControls: some View {
        HStack(spacing: 10) {
            Picker(String(localized: "Mode"), selection: style.redactionMode) {
                Text(String(localized: "Pixelate")).tag(RedactionMode.pixelate)
                Text(String(localized: "Blur")).tag(RedactionMode.blur)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            // The slider keeps its own value while dragging and applies it once, so a drag is one undo step.
            Slider(
                value: Binding(
                    get: { strength ?? model.currentStyle.redactionStrength }, set: { strength = $0 }),
                in: ToolStyle.strengthRange
            ) { isEditing in
                guard !isEditing, let strength else { return }
                style.wrappedValue.redactionStrength = strength
                self.strength = nil
            }
            .frame(width: 100)
            Image(systemName: "info.circle")
                .help(String(localized: "Use Pixelate for sensitive data; weak blur can sometimes be reversed."))
        }
    }

    private var cropControls: some View {
        let size = model.state.document.exportRectInPixels.size
        return HStack(spacing: 10) {
            Text("\(Int(size.width)) × \(Int(size.height)) px").monospacedDigit()
            Button(String(localized: "Reset")) { model.resetCrop() }
                .disabled(model.state.document.cropRectInPixels == nil)
        }
    }

    private func number(
        _ label: String, _ keyPath: WritableKeyPath<ToolStyle, CGFloat>, in range: ClosedRange<CGFloat>
    ) -> some View {
        let value = Binding(
            get: { Double(model.currentStyle[keyPath: keyPath]) },
            set: { style.wrappedValue[keyPath: keyPath] = CGFloat($0) })
        return HStack(spacing: 4) {
            Text(label).foregroundStyle(.secondary)
            TextField(label, value: value, format: .number.precision(.fractionLength(0...1)))
                .labelsHidden()
                .frame(width: 44)
            Stepper(label, value: value, in: Double(range.lowerBound)...Double(range.upperBound)).labelsHidden()
        }
    }
}
