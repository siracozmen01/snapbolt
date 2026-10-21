/// Lets the user pick a region, window or display on frozen screens.
@MainActor
public protocol SelectionPresenting {
    /// Shows the selection UI and returns the choice, or `nil` if the user cancelled.
    func select(on screens: FrozenScreens) async -> Selection?
}
