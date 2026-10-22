import SwiftUI

/// The tool buttons, one segment per tool, with the shortcut key in each tooltip.
struct ToolPickerView: View {
    let model: EditorModel

    var body: some View {
        Picker(
            String(localized: "Tool"),
            selection: Binding(get: { model.state.tool }, set: { model.selectTool($0) })
        ) {
            ForEach(EditorTool.allCases, id: \.self) { tool in
                Image(systemName: Self.symbol(for: tool))
                    .help("\(Self.name(of: tool)) (\(String(tool.shortcutKey).uppercased()))")
                    .tag(tool)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
    }

    private static func symbol(for tool: EditorTool) -> String {
        switch tool {
        case .select: "cursorarrow"
        case .arrow: "arrow.up.right"
        case .rectangle: "rectangle"
        case .text: "textformat"
        case .redaction: "eye.slash"
        case .crop: "crop"
        }
    }

    private static func name(of tool: EditorTool) -> String {
        switch tool {
        case .select: String(localized: "Select")
        case .arrow: String(localized: "Arrow")
        case .rectangle: String(localized: "Rectangle")
        case .text: String(localized: "Text")
        case .redaction: String(localized: "Redact")
        case .crop: String(localized: "Crop")
        }
    }
}
