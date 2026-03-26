import Foundation
import SQLite3

@MainActor
final class SyncManager: ObservableObject, SyncManagerProtocol {
    @Published private(set) var status: SyncStatus = .disabled
    @Published private(set) var isEnabled: Bool = false

    private let changeQueue: ChangeQueue
    private let conflictResolver: ConflictResolver
    private let httpClient: SyncHTTPClient
    private let noteRepo: NoteRepository
    private let taskRepo: TaskRepository
    private let db: DatabaseManager

    private var syncTimer: Timer?

    init(db: DatabaseManager, noteRepo: NoteRepository, taskRepo: TaskRepository) {
        self.db = db
        self.changeQueue = ChangeQueue(db: db)
        self.conflictResolver = ConflictResolver()
        self.httpClient = SyncHTTPClient()
        self.noteRepo = noteRepo
        self.taskRepo = taskRepo
    }

    func setEnabled(_ enabled: Bool) async throws {
        isEnabled = enabled
        status = enabled ? .idle : .disabled

        // Save setting
        db.execute("UPDATE app_settings SET value = '\(enabled ? "true" : "false")' WHERE key = 'sync_enabled'")

        if enabled {
            startPeriodicSync()
        } else {
            stopPeriodicSync()
        }
    }

    func configure(serverURL: URL, authToken: String) async throws {
        httpClient.configure(serverURL: serverURL, authToken: authToken)
        db.execute("UPDATE app_settings SET value = '\(serverURL.absoluteString)' WHERE key = 'sync_server_url'")
    }

    func sync() async throws {
        guard isEnabled else { return }
        status = .syncing

        do {
            try await pullChanges()
            try await pushChanges()
            status = .idle
        } catch {
            status = .error(error.localizedDescription)
            throw error
        }
    }

    func pushChanges() async throws {
        let unsynced = try changeQueue.fetchUnsynced()
        guard !unsynced.isEmpty else { return }

        // Gather changed entities
        var notes: [Note] = []
        var tasks: [NoteTask] = []
        var deletedNoteIDs: [String] = []
        var deletedTaskIDs: [String] = []

        for entry in unsynced {
            switch (entry.entityType, entry.operation) {
            case ("note", "delete"):
                deletedNoteIDs.append(entry.entityID)
            case ("note", _):
                if let note = try await noteRepo.fetchByID(entry.entityID) {
                    notes.append(note)
                }
            case ("task", "delete"):
                deletedTaskIDs.append(entry.entityID)
            case ("task", _):
                // Tasks fetched by note, handled via note sync
                break
            default:
                break
            }
        }

        let payload = SyncPushPayload(
            notes: notes,
            tasks: tasks,
            deletedNoteIDs: deletedNoteIDs,
            deletedTaskIDs: deletedTaskIDs
        )

        try await httpClient.push(payload)

        // Mark as synced
        let ids = unsynced.map(\.id)
        try changeQueue.markSynced(ids: ids)
    }

    func pullChanges() async throws {
        // Get last sync timestamp
        var lastSync: String?
        try db.query("SELECT value FROM app_settings WHERE key = 'last_sync_timestamp'") { stmt in
            let value = String(cString: sqlite3_column_text(stmt, 0))
            if !value.isEmpty { lastSync = value }
        }

        let response = try await httpClient.pull(since: lastSync)

        // Apply remote changes with conflict resolution
        for remoteNote in response.notes {
            if let localNote = try await noteRepo.fetchByID(remoteNote.id) {
                let winner = conflictResolver.resolve(local: localNote, remote: remoteNote)
                if winner.id == remoteNote.id && winner.updatedAt == remoteNote.updatedAt {
                    try await noteRepo.update(remoteNote)
                }
            } else {
                // New note from remote
                let _ = try await noteRepo.create(title: remoteNote.title, bodyHTML: remoteNote.bodyHTML)
            }
        }

        // Apply deletions
        for noteID in response.deletedNoteIDs {
            try await noteRepo.softDelete(id: noteID)
        }

        // Update last sync timestamp
        db.execute("UPDATE app_settings SET value = '\(response.serverTimestamp)' WHERE key = 'last_sync_timestamp'")
    }

    func recordChange(entityType: String, entityID: String, operation: String) async throws {
        try changeQueue.record(entityType: entityType, entityID: entityID, operation: operation)
    }

    func markSynced(ids: [Int]) async throws {
        try changeQueue.markSynced(ids: ids)
    }

    func fetchUnsyncedChanges() async throws -> [SyncLogEntry] {
        try changeQueue.fetchUnsynced()
    }

    func resolveConflict(local: Note, remote: Note) -> Note {
        conflictResolver.resolve(local: local, remote: remote)
    }

    // MARK: - Private

    private func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: HavenConstants.defaultSyncIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                try? await self?.sync()
            }
        }
    }

    private func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
}
