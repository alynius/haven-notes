import Foundation
import SQLite3

final class TaskRepository: TaskRepositoryProtocol {
    private let db: DatabaseManager

    init(db: DatabaseManager = .shared) {
        self.db = db
    }

    // MARK: - Create

    func create(noteID: String, text: String, position: Int) async throws -> NoteTask {
        let task = NoteTask(
            noteID: noteID,
            text: text,
            position: position
        )

        try db.performSync {
            let sql = """
                INSERT INTO \(HavenConstants.Database.tasksTable)
                (id, note_id, text, is_completed, position, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """
            try self.db.executeStatement(sql, params: [
                task.id,
                task.noteID,
                task.text,
                task.isCompleted ? 1 : 0,
                task.position,
                task.createdAt.iso8601String,
                task.updatedAt.iso8601String
            ])

            try self.recordSyncChange(entityType: "task", entityID: task.id, operation: "insert")
        }

        return task
    }

    // MARK: - Fetch

    func fetchTasks(for noteID: String) async throws -> [NoteTask] {
        try db.performSync {
            let sql = """
                SELECT id, note_id, text, is_completed, position, created_at, updated_at
                FROM \(HavenConstants.Database.tasksTable)
                WHERE note_id = ?
                ORDER BY position ASC
                """
            var tasks: [NoteTask] = []
            try self.db.query(sql, params: [noteID]) { stmt in
                tasks.append(self.taskFromRow(stmt))
            }
            return tasks
        }
    }

    // MARK: - Update

    func update(_ task: NoteTask) async throws {
        try db.performSync {
            let sql = """
                UPDATE \(HavenConstants.Database.tasksTable)
                SET text = ?, is_completed = ?, position = ?, updated_at = ?
                WHERE id = ?
                """
            try self.db.executeStatement(sql, params: [
                task.text,
                task.isCompleted ? 1 : 0,
                task.position,
                Date().iso8601String,
                task.id
            ])

            try self.recordSyncChange(entityType: "task", entityID: task.id, operation: "update")
        }
    }

    // MARK: - Toggle Complete

    func toggleComplete(id: String) async throws {
        try db.performSync {
            let sql = """
                UPDATE \(HavenConstants.Database.tasksTable)
                SET is_completed = CASE WHEN is_completed = 1 THEN 0 ELSE 1 END, updated_at = ?
                WHERE id = ?
                """
            try self.db.executeStatement(sql, params: [Date().iso8601String, id])
            try self.recordSyncChange(entityType: "task", entityID: id, operation: "update")
        }
    }

    // MARK: - Delete

    func delete(id: String) async throws {
        try db.performSync {
            let sql = "DELETE FROM \(HavenConstants.Database.tasksTable) WHERE id = ?"
            try self.db.executeStatement(sql, params: [id])
            try self.recordSyncChange(entityType: "task", entityID: id, operation: "delete")
        }
    }

    // MARK: - Reorder

    func reorder(noteID: String, taskIDs: [String]) async throws {
        try db.performSync {
            let now = Date().iso8601String
            let sql = """
                UPDATE \(HavenConstants.Database.tasksTable)
                SET position = ?, updated_at = ?
                WHERE id = ?
                """
            for (index, taskID) in taskIDs.enumerated() {
                try self.db.executeStatement(sql, params: [index, now, taskID])
            }

            try self.recordSyncChange(entityType: "task", entityID: noteID, operation: "reorder")
        }
    }

    // MARK: - Private Helpers

    private func taskFromRow(_ stmt: OpaquePointer) -> NoteTask {
        NoteTask(
            id: DatabaseManager.columnTextNonNull(stmt, 0),
            noteID: DatabaseManager.columnTextNonNull(stmt, 1),
            text: DatabaseManager.columnTextNonNull(stmt, 2),
            isCompleted: sqlite3_column_int(stmt, 3) == 1,
            position: Int(sqlite3_column_int(stmt, 4)),
            createdAt: Date(iso8601String: DatabaseManager.columnTextNonNull(stmt, 5)) ?? Date(),
            updatedAt: Date(iso8601String: DatabaseManager.columnTextNonNull(stmt, 6)) ?? Date()
        )
    }

    private func recordSyncChange(entityType: String, entityID: String, operation: String) throws {
        let sql = """
            INSERT INTO \(HavenConstants.Database.syncLogTable)
            (entity_type, entity_id, operation, timestamp)
            VALUES (?, ?, ?, ?)
            """
        try db.executeStatement(sql, params: [entityType, entityID, operation, Date().iso8601String])
    }
}
