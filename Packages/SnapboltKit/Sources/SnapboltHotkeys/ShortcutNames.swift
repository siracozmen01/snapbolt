import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Select a region or window: ⌥⇧4, next to the system's ⌘⇧4 without clashing with it.
    static let captureRegion = Self("captureRegion", initial: .init(.four, modifiers: [.option, .shift]))
    /// Capture the display under the cursor: ⌥⇧3.
    static let captureFullScreen = Self("captureFullScreen", initial: .init(.three, modifiers: [.option, .shift]))
}
