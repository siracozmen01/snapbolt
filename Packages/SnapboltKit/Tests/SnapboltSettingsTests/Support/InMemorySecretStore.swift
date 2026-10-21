import SnapboltCore
import Synchronization

@testable import SnapboltSettings

/// Keeps secrets in memory; can be told to fail like the Keychain would.
final class InMemorySecretStore: SecretStoring {
    private let secrets = Mutex<[String: String]>([:])
    private let failure: SettingsError?

    init(failure: SettingsError? = nil) {
        self.failure = failure
    }

    func secret(for account: String) throws(SettingsError) -> String? {
        if let failure { throw failure }
        return secrets.withLock { $0[account] }
    }

    func setSecret(_ secret: String, for account: String) throws(SettingsError) {
        if let failure { throw failure }
        secrets.withLock { $0[account] = secret }
    }

    func deleteSecret(for account: String) throws(SettingsError) {
        if let failure { throw failure }
        _ = secrets.withLock { $0.removeValue(forKey: account) }
    }
}
