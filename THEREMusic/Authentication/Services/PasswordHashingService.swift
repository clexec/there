import Foundation
import CryptoKit

// MARK: - PasswordHashingService
final class PasswordHashingService {

    static let shared = PasswordHashingService()
    private init() {}

    // MARK: - Hash
    func hash(_ password: String) -> String {
        let salt = generateSalt()
        return hashWithSalt(password, salt: salt)
    }

    func hashWithSalt(_ password: String, salt: String) -> String {
        let combined = password + salt
        guard let data = combined.data(using: .utf8) else { return "" }
        let digest = SHA512.hash(data: data)
        let hashString = digest.map { String(format: "%02x", $0) }.joined()
        return "\(salt):\(hashString)"
    }

    func verify(_ password: String, against storedHash: String) -> Bool {
        let parts = storedHash.components(separatedBy: ":")
        guard parts.count == 2 else { return false }
        let salt = parts[0]
        let computed = hashWithSalt(password, salt: salt)
        return computed == storedHash
    }

    // MARK: - PBKDF2 (stronger alternative)
    func hashPBKDF2(_ password: String, salt: Data? = nil) throws -> String {
        guard let passwordData = password.data(using: .utf8) else {
            throw AppErrorType.invalidInput("Invalid password encoding")
        }
        let saltData = salt ?? generateSaltData()
        let derivedKey = try PBKDF2SHA256(password: passwordData, salt: saltData, iterations: 100_000, keyLength: 32)
        let saltHex = saltData.map { String(format: "%02x", $0) }.joined()
        let keyHex  = derivedKey.map { String(format: "%02x", $0) }.joined()
        return "pbkdf2:\(saltHex):\(keyHex)"
    }

    func verifyPBKDF2(_ password: String, against storedHash: String) throws -> Bool {
        let parts = storedHash.components(separatedBy: ":")
        guard parts.count == 3, parts[0] == "pbkdf2" else { return false }
        guard
            let saltData = Data(hexString: parts[1]),
            let passwordData = password.data(using: .utf8)
        else { return false }
        let computed = try PBKDF2SHA256(password: passwordData, salt: saltData, iterations: 100_000, keyLength: 32)
        let computedHex = computed.map { String(format: "%02x", $0) }.joined()
        return computedHex == parts[2]
    }

    // MARK: - Private Helpers
    private func generateSalt(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private func generateSaltData(length: Int = 32) -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return Data(bytes)
    }

    private func PBKDF2SHA256(password: Data, salt: Data, iterations: Int, keyLength: Int) throws -> Data {
        var derivedKeyData = Data(repeating: 0, count: keyLength)
        let derivationStatus = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                password.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress, password.count,
                        saltBytes.baseAddress, salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.baseAddress, keyLength
                    )
                }
            }
        }
        guard derivationStatus == kCCSuccess else {
            throw AppErrorType.authFailed("Password hashing failed")
        }
        return derivedKeyData
    }
}

// MARK: - Data Hex Extension
extension Data {
    init?(hexString: String) {
        let length = hexString.count / 2
        var data = Data(capacity: length)
        var index = hexString.startIndex
        for _ in 0..<length {
            let next = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        self = data
    }
}
