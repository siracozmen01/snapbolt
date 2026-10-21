import Foundation
import Security
import SnapboltCore

/// Generic-password Keychain items under one service.
struct KeychainSecretStore: SecretStoring {
    static let service = "\(Snapbolt.bundleIdentifier).storage"

    func secret(for account: String) throws(SettingsError) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw .keychain(status: status) }
        guard let secret = String(data: data, encoding: .utf8) else { throw .keychain(status: errSecDecode) }
        return secret
    }

    func setSecret(_ secret: String, for account: String) throws(SettingsError) {
        let data = Data(secret.utf8)
        let updateStatus = SecItemUpdate(
            baseQuery(account: account) as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else { throw .keychain(status: updateStatus) }
        var item = baseQuery(account: account)
        item[kSecValueData as String] = data
        let addStatus = SecItemAdd(item as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw .keychain(status: addStatus) }
    }

    func deleteSecret(for account: String) throws(SettingsError) {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw .keychain(status: status) }
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: account,
        ]
    }
}
