/// A tool's response to one press-drag-release gesture. Tools are pure: they return the next state and
/// keep only the gesture in progress.
protocol ToolInteraction {
    mutating func began(_ input: PointerInput, in state: EditorState) -> EditorState
    mutating func moved(_ input: PointerInput, in state: EditorState) -> EditorState
    mutating func ended(_ input: PointerInput, in state: EditorState) -> EditorState
}
