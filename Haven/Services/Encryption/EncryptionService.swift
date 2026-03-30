import Foundation
import CryptoKit
import CommonCrypto

final class EncryptionService {

    private var masterKey: SymmetricKey?

    // MARK: - Key Management

    /// Derive master key from password using PBKDF2
    func deriveKey(from password: String, salt: Data? = nil) -> (key: SymmetricKey, salt: Data) {
        let keySalt = salt ?? generateSalt()

        // PBKDF2 with SHA256, 600K iterations (OWASP 2023 recommendation)
        let passwordData = Data(password.utf8)
        var derivedKey = Data(count: 32) // 256 bits

        derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            keySalt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        keySalt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        600_000,
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        32
                    )
                }
            }
        }

        let key = SymmetricKey(data: derivedKey)
        self.masterKey = key
        return (key, keySalt)
    }

    private func generateSalt() -> Data {
        var salt = Data(count: 32)
        _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }
        return salt
    }

    /// Set master key directly (loaded from Keychain)
    func setMasterKey(_ key: SymmetricKey) {
        self.masterKey = key
    }

    var hasKey: Bool { masterKey != nil }

    // MARK: - Keychain Storage

    private let keychainService = "com.haven.encryption"
    private let keychainKeyAccount = "masterKey"
    private let keychainSaltAccount = "masterSalt"

    func saveKeyToKeychain(keyData: Data, salt: Data) throws {
        // Save key
        try saveToKeychain(account: keychainKeyAccount, data: keyData)
        // Save salt
        try saveToKeychain(account: keychainSaltAccount, data: salt)
    }

    func loadKeyFromKeychain() -> (key: SymmetricKey, salt: Data)? {
        guard let keyData = loadFromKeychain(account: keychainKeyAccount),
              let salt = loadFromKeychain(account: keychainSaltAccount) else {
            return nil
        }
        let key = SymmetricKey(data: keyData)
        self.masterKey = key
        return (key, salt)
    }

    func deleteKeyFromKeychain() {
        deleteFromKeychain(account: keychainKeyAccount)
        deleteFromKeychain(account: keychainSaltAccount)
        masterKey = nil
    }

    private func saveToKeychain(account: String, data: Data) throws {
        // Delete existing
        deleteFromKeychain(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keychainError(status)
        }
    }

    private func loadFromKeychain(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func deleteFromKeychain(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Encrypt / Decrypt

    /// Encrypt a string using AES-256-GCM. Returns base64-encoded sealed box.
    func encrypt(_ plaintext: String) throws -> String {
        guard let key = masterKey else { throw EncryptionError.noKey }
        let data = Data(plaintext.utf8)
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else { throw EncryptionError.encryptionFailed }
        return combined.base64EncodedString()
    }

    /// Decrypt a base64-encoded AES-256-GCM sealed box. Returns plaintext string.
    func decrypt(_ base64Ciphertext: String) throws -> String {
        guard let key = masterKey else { throw EncryptionError.noKey }
        guard let combined = Data(base64Encoded: base64Ciphertext) else {
            throw EncryptionError.invalidData
        }
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        let decrypted = try AES.GCM.open(sealedBox, using: key)
        guard let plaintext = String(data: decrypted, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        return plaintext
    }

    /// Encrypt a Note for sync. Returns an encrypted copy.
    func encryptNote(_ note: Note) throws -> Note {
        var encrypted = note
        encrypted.title = try encrypt(note.title)
        encrypted.bodyHTML = try encrypt(note.bodyHTML)
        encrypted.bodyPlaintext = try encrypt(note.bodyPlaintext)
        return encrypted
    }

    /// Decrypt a Note received from sync. Returns a plaintext copy.
    func decryptNote(_ note: Note) throws -> Note {
        var decrypted = note
        decrypted.title = try decrypt(note.title)
        decrypted.bodyHTML = try decrypt(note.bodyHTML)
        decrypted.bodyPlaintext = try decrypt(note.bodyPlaintext)
        return decrypted
    }
}

enum EncryptionError: Error, LocalizedError {
    case noKey
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case keychainError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .noKey: return "No encryption key. Please set up encryption in Settings."
        case .encryptionFailed: return "Failed to encrypt data"
        case .decryptionFailed: return "Failed to decrypt data. Wrong password?"
        case .invalidData: return "Invalid encrypted data"
        case .keychainError(let status): return "Keychain error: \(status)"
        }
    }
}
