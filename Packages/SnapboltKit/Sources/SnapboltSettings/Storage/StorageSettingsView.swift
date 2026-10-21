import SwiftUI

/// The Storage tab: S3-compatible endpoint, bucket, keys and public URL.
public struct StorageSettingsView: View {
    @Bindable private var model: StorageSettingsModel

    /// Creates the tab for `model`.
    public init(model: StorageSettingsModel) {
        self.model = model
    }

    /// The view's content.
    public var body: some View {
        Form {
            Section {
                TextField(
                    "Endpoint", text: $model.draft.endpoint,
                    prompt: Text("https://<account-id>.r2.cloudflarestorage.com"))
                TextField("Region", text: $model.draft.region, prompt: Text("auto"))
                TextField("Bucket", text: $model.draft.bucket)
            } footer: {
                Text("For Cloudflare R2, use the S3 API endpoint of your account and region auto.")
            }
            Section {
                TextField("Access Key ID", text: $model.draft.accessKeyID)
                SecureField("Secret Access Key", text: $model.draft.secretAccessKey)
            } footer: {
                Text("The secret key is stored in your Keychain.")
            }
            Section {
                TextField("Public base URL", text: $model.draft.publicBaseURL, prompt: Text("https://i.example.com"))
                TextField("Key template", text: $model.draft.keyTemplate)
            } footer: {
                Text("Tokens: {yyyy} {MM} {dd} {HH} {mm} {ss} {random}. {random} is required.")
            }
            StorageActionsView(model: model)
        }
        .formStyle(.grouped)
        .textFieldStyle(.roundedBorder)
        .autocorrectionDisabled()
    }
}

/// Save and Test Connection buttons with their status.
private struct StorageActionsView: View {
    let model: StorageSettingsModel

    var body: some View {
        Section {
            HStack {
                Button("Test Connection") {
                    Task { await model.testConnection() }
                }
                .disabled(model.testStatus == .testing)
                Spacer()
                Button("Save") { model.save() }
                    .keyboardShortcut(.defaultAction)
            }
            if let message = model.validationMessage {
                Label(message, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
            }
            TestStatusView(status: model.testStatus)
        }
    }
}

private struct TestStatusView: View {
    let status: StorageSettingsModel.TestStatus

    var body: some View {
        switch status {
        case .idle:
            EmptyView()
        case .testing:
            HStack {
                ProgressView().controlSize(.small)
                Text("Testing…")
            }
        case .succeeded:
            Label("Connection works.", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed(let message):
            Label(message, systemImage: "xmark.octagon.fill").foregroundStyle(.red)
        }
    }
}
