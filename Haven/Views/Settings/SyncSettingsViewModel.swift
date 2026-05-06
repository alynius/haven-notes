import SwiftUI

@MainActor
final class SyncSettingsViewModel: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var serverURL: String = ""
    @Published var authToken: String = ""
    @Published var syncStatus: SyncStatus = .disabled
    @Published var unsyncedCount: Int = 0
    @Published var errorMessage: String?

    private let syncManager: SyncManagerProtocol

    init(syncManager: SyncManagerProtocol) {
        self.syncManager = syncManager
        self.isEnabled = syncManager.isEnabled
        self.syncStatus = syncManager.status
    }

    func toggleSync() async {
        do {
            try await syncManager.setEnabled(!isEnabled)
            isEnabled = syncManager.isEnabled
            syncStatus = syncManager.status
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveConfiguration() async -> Bool {
        let trimmedURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedURL),
              url.scheme?.lowercased() == "https",
              url.host?.isEmpty == false else {
            errorMessage = "Server URL must be a valid HTTPS URL (e.g. https://sync.example.com)."
            return false
        }
        let trimmedToken = authToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else {
            errorMessage = "Auth token cannot be empty."
            return false
        }
        do {
            try await syncManager.configure(serverURL: url, authToken: trimmedToken)
            // Persist the trimmed forms back so the fields stay clean after save.
            serverURL = trimmedURL
            authToken = trimmedToken
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// True when sync is enabled but the user hasn't entered server credentials yet.
    var isConfigurationIncomplete: Bool {
        isEnabled && (serverURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      || authToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    func syncNow() async {
        do {
            try await syncManager.sync()
            syncStatus = syncManager.status
        } catch {
            errorMessage = error.localizedDescription
            syncStatus = syncManager.status
        }
    }

    func loadUnsyncedCount() async {
        do {
            let unsynced = try await syncManager.fetchUnsyncedChanges()
            unsyncedCount = unsynced.count
        } catch {
            unsyncedCount = 0
        }
    }
}
