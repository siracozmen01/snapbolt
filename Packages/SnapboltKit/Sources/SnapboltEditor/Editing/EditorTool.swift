/// The tools in the editor's toolbar, in toolbar order.
enum EditorTool: String, CaseIterable, Codable, Sendable {
    case select
    case arrow
    case rectangle
    case text
    case redaction
    case crop

    /// Creates the tool whose single-key shortcut is `shortcutKey`.
    init?(shortcutKey: Character) {
        guard let tool = Self.allCases.first(where: { $0.shortcutKey == shortcutKey }) else { return nil }
        self = tool
    }

    /// The key that selects this tool when no text is being edited.
    var shortcutKey: Character {
        switch self {
        case .select: "v"
        case .arrow: "a"
        case .rectangle: "r"
        case .text: "t"
        case .redaction: "b"
        case .crop: "c"
        }
    }
}
