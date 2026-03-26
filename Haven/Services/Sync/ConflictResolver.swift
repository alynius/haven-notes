import Foundation

final class ConflictResolver {

    /// Resolve a conflict between local and remote versions of a note.
    /// Uses last-write-wins: the version with the more recent `updatedAt` wins.
    func resolve(local: Note, remote: Note) -> Note {
        if remote.updatedAt > local.updatedAt {
            return remote
        }
        return local
    }

    /// Resolve a conflict between local and remote versions of a task.
    func resolve(local: NoteTask, remote: NoteTask) -> NoteTask {
        if remote.updatedAt > local.updatedAt {
            return remote
        }
        return local
    }

    /// Determine if a remote change conflicts with a local change.
    /// A conflict exists when both sides have modified the same entity
    /// since the last successful sync.
    func hasConflict(localUpdatedAt: Date, remoteUpdatedAt: Date, lastSyncAt: Date?) -> Bool {
        guard let lastSync = lastSyncAt else {
            // Never synced before — no conflict possible
            return false
        }
        // Both modified after last sync = conflict
        return localUpdatedAt > lastSync && remoteUpdatedAt > lastSync
    }
}
