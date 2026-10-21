import SwiftUI

/// The first-launch window: explains and requests the permissions Snapbolt needs.
public struct OnboardingView: View {
    private let model: OnboardingModel

    /// Creates the view for `model`.
    public init(model: OnboardingModel) {
        self.model = model
    }

    /// The view's content.
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Welcome to Snapbolt").font(.largeTitle.bold())
            Text("Snapbolt needs two permissions to capture your screen and tell you when a link is ready.")
                .foregroundStyle(.secondary)
            ScreenRecordingStepView(model: model)
            NotificationsStepView(model: model)
            HStack {
                Spacer()
                Button("Continue") { model.finish() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 520)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refresh()
        }
    }
}

private struct ScreenRecordingStepView: View {
    let model: OnboardingModel

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label("Screen Recording", systemImage: "rectangle.dashed.badge.record").font(.headline)
                if model.hasScreenRecordingPermission {
                    Label("Granted", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                } else {
                    Text("Required to capture the screen. After allowing it, quit and reopen Snapbolt.")
                    HStack {
                        Button("Allow…") { model.grantScreenRecording() }
                        Button("Open System Settings") { model.openScreenRecordingSettings() }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct NotificationsStepView: View {
    let model: OnboardingModel

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label("Notifications", systemImage: "bell.badge").font(.headline)
                switch model.notificationsAllowed {
                case true?:
                    Label("Allowed", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                case false?:
                    Text("Not allowed. You can change this in System Settings › Notifications.")
                case nil:
                    Text("Optional. Shows when a link was copied or an upload failed.")
                    Button("Allow Notifications") {
                        Task { await model.requestNotifications() }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
