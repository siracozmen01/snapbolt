import AppKit

/// A checkable menu item whose check mark is read from `isOn` every time the menu opens.
@MainActor
final class ToggleMenuItem: NSMenuItem, NSMenuItemValidation {
    private let isOn: @MainActor () -> Bool
    private let toggle: @MainActor () -> Void

    init(title: String, isOn: @escaping @MainActor () -> Bool, toggle: @escaping @MainActor () -> Void) {
        self.isOn = isOn
        self.toggle = toggle
        super.init(title: title, action: #selector(run), keyEquivalent: "")
        target = self
        state = isOn() ? .on : .off
    }

    @available(*, unavailable, message: "Created in code only")
    required init(coder: NSCoder) {
        preconditionFailure("ToggleMenuItem is never loaded from a nib")
    }

    // AppKit validates enabled items each time their menu opens, so the check mark follows changes
    // made elsewhere, such as in Settings.
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        state = isOn() ? .on : .off
        return true
    }

    @objc private func run() {
        toggle()
    }
}
