import AppKit

/// A menu item that runs a closure instead of sending an action through the responder chain.
@MainActor
final class ClosureMenuItem: NSMenuItem {
    private let handler: @MainActor () -> Void

    init(title: String, keyEquivalent: String = "", handler: @escaping @MainActor () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(run), keyEquivalent: keyEquivalent)
        target = self
    }

    @available(*, unavailable, message: "Created in code only")
    required init(coder: NSCoder) {
        preconditionFailure("ClosureMenuItem is never loaded from a nib")
    }

    @objc private func run() {
        handler()
    }
}
