import Foundation

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
    private let encryptionService: EncryptionService

    private var syncTimer: Timer?

    init(db: DatabaseManager, noteRepo: NoteRepository, taskRepo: TaskRepository, encryptionService: EncryptionService) {
        self.db = db
        self.changeQueue = ChangeQueue(db: db)
        self.conflictResolver = ConflictResolver()
        self.httpClient = SyncHTTPClient()
        self.noteRepo = noteRepo
        self.taskRepo = taskRepo
        self.encryptionService = encryptionService
    }

    func setEnabled(_ enabled: Bool) async throws {
        isEnabled = enabled
        status = enabled ? .idle : .disabled

        // Save setting
        try db.executeStatement(
            "UPDATE app_settings SET value = ? WHERE key = 'sync_enabled'",
            params: [enabled ? "true" : "false"]
        )

        if enabled {
            startPeriodicSync()
        } else {
            stopPeriodicSync()
            httpClient.clearCredentials()
        }
    }

    func configure(serverURL: URL, authToken: String) async throws {
        httpClient.configure(serverURL: serverURL, authToken: authToken)
        try db.executeStatement(
            "UPDATE app_settings SET value = ? WHERE key = 'sync_server_url'",
            params: [serverURL.absoluteString]
        )
    }

    func sync() async throws {
        guard isEnabled else { return }
        status = .syncing

        do {
            try await pullChanges()
            try await pushChanges()
            // Purge synced log entries older than 30 days to prevent unbounded growth
            try changeQueue.purgeSynced(olderThan: Date().addingTimeInterval(-30 * 86400))
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

        // Collect unique note IDs that have task changes so we can fetch their tasks
        var noteIDsWithTaskChanges: Set<String> = []

        for entry in unsynced {
            switch (entry.entityType, entry.operation) {
            case ("note", "delete"):
                deletedNoteIDs.append(entry.entityID)
            case ("note", _):
                if var note = try await noteRepo.fetchByID(entry.entityID) {
                    if encryptionService.hasKey {
                        note = try encryptionService.encryptNote(note)
                    }
                    notes.append(note)
                }
            case ("task", "delete"):
                deletedTaskIDs.append(entry.entityID)
            case ("task", _):
                // Look up the note_id for this task to fetch all tasks for that note
                let taskID = entry.entityID
                try db.query(
                    "SELECT note_id FROM \(HavenConstants.Database.tasksTable) WHERE id = ?",
                    params: [taskID]
                ) { stmt in
                    let noteID = DatabaseManager.columnTextNonNull(stmt, 0)
                    noteIDsWithTaskChanges.insert(noteID)
                }
            default:
                break
            }
        }

        // Fetch tasks for notes that had task changes
        for noteID in noteIDsWithTaskChanges {
            let noteTasks = try await taskRepo.fetchTasks(for: noteID)
            tasks.append(contentsOf: noteTasks)
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
            let value = DatabaseManager.columnTextNonNull(stmt, 0)
            if !value.isEmpty { lastSync = value }
        }

        let response = try await httpClient.pull(since: lastSync)

        // Apply remote changes with conflict resolution
        for remoteNote in response.notes {
            // Decrypt if encryption is enabled
            var decryptedNote = remoteNote
            if encryptionService.hasKey {
                decryptedNote = try encryptionService.decryptNote(remoteNote)
            }

            if let localNote = try await noteRepo.fetchByID(decryptedNote.id) {
                let winner = conflictResolver.resolve(local: localNote, remote: decryptedNote)
                if winner.id == decryptedNote.id && winner.updatedAt == decryptedNote.updatedAt {
                    try await noteRepo.update(decryptedNote)
                }
            } else {
                // New note from remote — upsert to preserve the remote note's original ID
                try await noteRepo.upsert(decryptedNote)
            }
        }

        // Apply deletions
        for noteID in response.deletedNoteIDs {
            try await noteRepo.softDelete(id: noteID)
        }

        // Update last sync timestamp
        try db.executeStatement(
            "UPDATE app_settings SET value = ? WHERE key = 'last_sync_timestamp'",
            params: [response.serverTimestamp]
        )
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
        syncTimer?.tolerance = 60
    }

    private func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
}
