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

    func saveConfiguration() async {
        guard let url = URL(string: serverURL), !authToken.isEmpty else {
            errorMessage = "Please enter a valid server URL and auth token"
            return
        }
        do {
            try await syncManager.configure(serverURL: url, authToken: authToken)
        } catch {
            errorMessage = error.localizedDescription
        }
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
