import SnapboltCore

/// Stores secrets outside UserDefaults.
protocol SecretStoring: Sendable {
    func secret(for account: String) throws(SettingsError) -> String?
    func setSecret(_ secret: String, for account: String) throws(SettingsError)
    func deleteSecret(for account: String) throws(SettingsError)
}
