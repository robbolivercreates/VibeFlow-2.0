import Foundation
import Security

/// Generates and persists a unique device identifier in the Keychain.
/// Survives app reinstalls. Used for abuse detection server-side.
class DeviceManager {
    static let shared = DeviceManager()

    private let service = "com.voxaigo.app"
    private let account = "device_id"

    private init() {}

    var deviceID: String {
        if let existing = loadFromKeychain() {
            return existing
        }
        let new = UUID().uuidString
        saveToKeychain(new)
        return new
    }

    private func loadFromKeychain() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service as CFString,
            kSecAttrAccount: account as CFString,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }

    private func saveToKeychain(_ value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service as CFString,
            kSecAttrAccount: account as CFString,
            kSecValueData: data as CFData
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
}
