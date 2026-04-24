import Foundation
import SQLite3

final class ChangeQueue {
    private let db: DatabaseManager

    init(db: DatabaseManager) {
        self.db = db
    }

    /// Record a local change to be synced later.
    func record(entityType: String, entityID: String, operation: String) throws {
        let sql = """
            INSERT INTO sync_log (entity_type, entity_id, operation, timestamp)
            VALUES (?, ?, ?, ?)
        """
        try db.executeStatement(sql, params: [entityType, entityID, operation, Date().iso8601String])
    }

    /// Fetch all unsynced changes (where synced_at IS NULL).
    func fetchUnsynced() throws -> [SyncLogEntry] {
        var entries: [SyncLogEntry] = []
        let sql = "SELECT id, entity_type, entity_id, operation, timestamp, synced_at FROM sync_log WHERE synced_at IS NULL ORDER BY id ASC"
        try db.query(sql) { stmt in
            let entry = SyncLogEntry(
                id: Int(sqlite3_column_int64(stmt, 0)),
                entityType: DatabaseManager.columnTextNonNull(stmt, 1),
                entityID: DatabaseManager.columnTextNonNull(stmt, 2),
                operation: DatabaseManager.columnTextNonNull(stmt, 3),
                timestamp: Date(iso8601String: DatabaseManager.columnTextNonNull(stmt, 4)) ?? Date(),
                syncedAt: nil
            )
            entries.append(entry)
        }
        return entries
    }

    /// Mark entries as synced with current timestamp.
    func markSynced(ids: [Int]) throws {
        guard !ids.isEmpty else { return }
        let placeholders = ids.map { _ in "?" }.joined(separator: ", ")
        let sql = "UPDATE sync_log SET synced_at = ? WHERE id IN (\(placeholders))"
        let now = Date().iso8601String
        var params: [Any?] = [now]
        params.append(contentsOf: ids.map { $0 as Any? })
        try db.executeStatement(sql, params: params)
    }

    /// Purge synced entries older than given date to prevent unbounded growth.
    func purgeSynced(olderThan date: Date) throws {
        let sql = "DELETE FROM sync_log WHERE synced_at IS NOT NULL AND synced_at < ?"
        try db.executeStatement(sql, params: [date.iso8601String])
    }
}
