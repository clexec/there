import Foundation
import Security

// MARK: - KeychainService
final class KeychainService {

    static let shared = KeychainService()
    private let service = AppConstants.Keychain.serviceName
    private init() {}

    // MARK: - Save
    @discardableResult
    func save(_ data: Data, for key: String, accessible: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) -> Bool {
        delete(key: key)
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      key,
            kSecValueData:        data,
            kSecAttrAccessible:   accessible
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    @discardableResult
    func save(_ string: String, for key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data, for: key)
    }

    func saveCodable<T: Codable>(_ value: T, for key: String) throws {
        let data = try JSONEncoder().encode(value)
        guard save(data, for: key) else {
            throw AppErrorType.keychainError("Failed to save \(key) to Keychain")
        }
    }

    // MARK: - Load
    func load(key: String) -> Data? {
        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrService:     service,
            kSecAttrAccount:     key,
            kSecReturnData:      true,
            kSecMatchLimit:      kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    func loadString(key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func loadCodable<T: Codable>(_ type: T.Type, key: String) throws -> T? {
        guard let data = load(key: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Delete
    @discardableResult
    func delete(key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    func deleteAll() {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Check
    func exists(key: String) -> Bool { load(key: key) != nil }

    // MARK: - Specific Auth Methods
    func saveAppleToken(_ token: String)        { save(token, for: AppConstants.Keychain.appleTokenKey) }
    func loadAppleToken() -> String?            { loadString(key: AppConstants.Keychain.appleTokenKey) }
    func deleteAppleToken()                     { delete(key: AppConstants.Keychain.appleTokenKey) }

    func saveGoogleToken(_ token: String)       { save(token, for: AppConstants.Keychain.googleTokenKey) }
    func loadGoogleToken() -> String?           { loadString(key: AppConstants.Keychain.googleTokenKey) }
    func saveGoogleRefresh(_ token: String)     { save(token, for: AppConstants.Keychain.googleRefreshKey) }
    func loadGoogleRefresh() -> String?         { loadString(key: AppConstants.Keychain.googleRefreshKey) }
    func deleteGoogleTokens()                   { delete(key: AppConstants.Keychain.googleTokenKey); delete(key: AppConstants.Keychain.googleRefreshKey) }

    func saveEmailSession(_ session: AuthSession) throws { try saveCodable(session, for: AppConstants.Keychain.emailAuthKey) }
    func loadEmailSession() throws -> AuthSession?      { try loadCodable(AuthSession.self, key: AppConstants.Keychain.emailAuthKey) }
    func deleteEmailSession()                           { delete(key: AppConstants.Keychain.emailAuthKey) }

    func saveUserID(_ id: String)               { save(id, for: AppConstants.Keychain.userIDKey) }
    func loadUserID() -> String?                { loadString(key: AppConstants.Keychain.userIDKey) }

    func clearAllAuthData() {
        deleteAppleToken()
        deleteGoogleTokens()
        deleteEmailSession()
        delete(key: AppConstants.Keychain.userIDKey)
    }
}
