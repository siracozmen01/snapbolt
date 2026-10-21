import AppKit
import SnapboltCore
import SnapboltSettings
import SwiftUI

/// Owns the first-launch window.
@MainActor
final class OnboardingWindowController {
    private var window: NSWindow?

    /// Shows onboarding; `onFinish` runs after the window closes via Continue.
    func show(permissions: any PermissionChecking, onFinish: @escaping @MainActor () -> Void) {
        let model = OnboardingModel(permissions: permissions) { [weak self] in
            self?.window?.close()
            onFinish()
        }
        let window = NSWindow(contentViewController: NSHostingController(rootView: OnboardingView(model: model)))
        window.title = String(localized: "Welcome to Snapbolt")
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}
