import AppKit

/// Entry point. `@main` lives here rather than on the delegate because, without a main nib,
/// AppKit never instantiates an `NSApplicationDelegate` marked `@main`.
@main
enum SnapboltMain {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.run()
    }
}
