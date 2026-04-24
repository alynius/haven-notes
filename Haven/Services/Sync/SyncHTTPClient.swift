import Foundation
import Security

/// Represents a batch of changes to send to the server.
struct SyncPushPayload: Codable {
    let notes: [Note]
    let tasks: [NoteTask]
    let deletedNoteIDs: [String]
    let deletedTaskIDs: [String]
}

/// Represents a batch of changes received from the server.
struct SyncPullResponse: Codable {
    let notes: [Note]
    let tasks: [NoteTask]
    let deletedNoteIDs: [String]
    let deletedTaskIDs: [String]
    let serverTimestamp: String
}

final class SyncHTTPClient {
    private var serverURL: URL?
    private var authToken: String?
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private let keychainService = "com.haven.sync"
    private let keychainAccount = "authToken"

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        // Restore persisted token so sync survives app restarts
        self.authToken = loadStoredToken()
    }

    func configure(serverURL: URL, authToken: String) {
        self.serverURL = serverURL
        self.authToken = authToken
        saveTokenToKeychain(authToken)
    }

    /// Clear credentials and remove token from Keychain (call on disconnect).
    func clearCredentials() {
        serverURL = nil
        authToken = nil
        deleteTokenFromKeychain()
    }

    // MARK: - Keychain helpers

    private func saveTokenToKeychain(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        // Delete any existing entry first
        deleteTokenFromKeychain()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadStoredToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    private func deleteTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// Push local changes to the server.
    func push(_ payload: SyncPushPayload) async throws {
        guard let url = serverURL?.appendingPathComponent("sync/push"),
              let token = authToken else {
            throw SyncHTTPError.notConfigured
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(payload)

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SyncHTTPError.serverError
        }
    }

    /// Pull remote changes since the given timestamp.
    func pull(since timestamp: String?) async throws -> SyncPullResponse {
        guard var urlComponents = serverURL.flatMap({ URLComponents(url: $0.appendingPathComponent("sync/pull"), resolvingAgainstBaseURL: false) }),
              let token = authToken else {
            throw SyncHTTPError.notConfigured
        }

        if let timestamp = timestamp {
            urlComponents.queryItems = [URLQueryItem(name: "since", value: timestamp)]
        }

        guard let url = urlComponents.url else {
            throw SyncHTTPError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SyncHTTPError.serverError
        }

        return try decoder.decode(SyncPullResponse.self, from: data)
    }
}

enum SyncHTTPError: Error, LocalizedError {
    case notConfigured
    case invalidURL
    case serverError
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Sync server not configured"
        case .invalidURL: return "Invalid sync URL"
        case .serverError: return "Sync server error"
        case .decodingFailed: return "Failed to decode sync response"
        }
    }
}
