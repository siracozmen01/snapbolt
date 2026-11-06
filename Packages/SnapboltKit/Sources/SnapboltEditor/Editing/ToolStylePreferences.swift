import Foundation

/// Remembers the last style of each tool across captures and launches.
@MainActor
struct ToolStylePreferences {
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// The saved styles; tools without a readable saved style are left out.
    func load() -> [EditorTool: ToolStyle] {
        var styles: [EditorTool: ToolStyle] = [:]
        for tool in EditorTool.allCases {
            guard let data = defaults.data(forKey: Self.key(for: tool)) else { continue }
            do {
                styles[tool] = try JSONDecoder().decode(ToolStyle.self, from: data)
            } catch {
                // A style from an older or damaged preference only costs the user their last choice; the
                // tool falls back to the standard style rather than failing to open the editor.
                logger.error("Ignoring an unreadable \(tool.rawValue, privacy: .public) style")
            }
        }
        return styles
    }

    func save(_ style: ToolStyle, for tool: EditorTool) {
        do {
            defaults.set(try JSONEncoder().encode(style), forKey: Self.key(for: tool))
        } catch {
            // Encoding a plain struct of numbers and strings does not fail in practice; losing one remembered
            // style is harmless.
            logger.error("Could not save the \(tool.rawValue, privacy: .public) style")
        }
    }

    private static func key(for tool: EditorTool) -> String {
        "editor.style.\(tool.rawValue)"
    }
}
