import Foundation
import Security

enum KeychainError: Error, LocalizedError {
    case itemNotFound
    case unexpectedData
    case unhandledError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .itemNotFound: return "Passphrase not found in Keychain"
        case .unexpectedData: return "Unexpected data format in Keychain"
        case .unhandledError(let s): return "Keychain error: \(s)"
        }
    }
}

struct KeychainService {
    private static let service = "com.qdecosne.Viaduct"

    static func savePassphrase(_ passphrase: String, for tunnelID: UUID) throws {
        let data = Data(passphrase.utf8)
        let account = tunnelID.uuidString
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        let attributes: [CFString: Any] = [kSecValueData: data]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var add = query
            add[kSecValueData] = data
            let addStatus = SecItemAdd(add as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unhandledError(addStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unhandledError(status)
        }
    }

    static func loadPassphrase(for tunnelID: UUID) throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: tunnelID.uuidString,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound { throw KeychainError.itemNotFound }
            throw KeychainError.unhandledError(status)
        }
        guard let data = result as? Data, let str = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return str
    }

    static func deletePassphrase(for tunnelID: UUID) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: tunnelID.uuidString
        ]
        SecItemDelete(query as CFDictionary)
    }
}
