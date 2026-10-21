import SwiftUI

/// The General tab: local copies and launch at login.
public struct GeneralSettingsView: View {
    @Bindable private var model: GeneralSettingsModel
    @State private var isChoosingFolder = false

    /// Creates the tab for `model`.
    public init(model: GeneralSettingsModel) {
        self.model = model
    }

    /// The view's content.
    public var body: some View {
        Form {
            Section("Local copies") {
                Toggle("Save a copy of every capture", isOn: $model.saveLocally)
                LabeledContent("Folder") {
                    HStack {
                        Text(model.folder.path(percentEncoded: false)).lineLimit(1).truncationMode(.middle)
                        Button("Choose…") { isChoosingFolder = true }
                    }
                }
                .disabled(!model.saveLocally)
            }
            Section("Startup") {
                Toggle(
                    "Launch Snapbolt at login",
                    isOn: Binding(
                        get: { model.launchAtLoginEnabled },
                        set: { model.setLaunchAtLogin($0) }
                    ))
                if let message = model.errorMessage {
                    Text(message).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .fileImporter(isPresented: $isChoosingFolder, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result { model.folder = url }
        }
    }
}
