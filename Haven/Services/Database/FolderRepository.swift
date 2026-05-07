import Foundation
import SQLite3

final class FolderRepository: FolderRepositoryProtocol {
    private let db: DatabaseManager

    init(db: DatabaseManager) { self.db = db }

    func fetchAll() async throws -> [Folder] {
        var folders: [Folder] = []
        try db.query("SELECT id, name, position, created_at, updated_at, color FROM folders ORDER BY position ASC") { stmt in
            folders.append(Folder(
                id: DatabaseManager.columnTextNonNull(stmt, 0),
                name: DatabaseManager.columnTextNonNull(stmt, 1),
                position: Int(sqlite3_column_int(stmt, 2)),
                color: DatabaseManager.columnText(stmt, 5),
                createdAt: Date(iso8601String: DatabaseManager.columnTextNonNull(stmt, 3)) ?? Date(),
                updatedAt: Date(iso8601String: DatabaseManager.columnTextNonNull(stmt, 4)) ?? Date()
            ))
        }
        return folders
    }

    func create(name: String) async throws -> Folder {
        let folder = Folder(name: name, position: 0)
        try db.executeStatement(
            "INSERT INTO folders (id, name, position, created_at, updated_at, color) VALUES (?, ?, ?, ?, ?, ?)",
            params: [folder.id, folder.name, folder.position, folder.createdAt.iso8601String, folder.updatedAt.iso8601String, folder.color]
        )
        return folder
    }

    func rename(id: String, name: String) async throws {
        try db.executeStatement(
            "UPDATE folders SET name = ?, updated_at = ? WHERE id = ?",
            params: [name, Date().iso8601String, id]
        )
    }

    func setColor(id: String, color: String?) async throws {
        try db.executeStatement(
            "UPDATE folders SET color = ?, updated_at = ? WHERE id = ?",
            params: [color, Date().iso8601String, id]
        )
    }

    func delete(id: String) async throws {
        // ON DELETE SET NULL handles moving notes to unassigned
        try db.executeStatement("DELETE FROM folders WHERE id = ?", params: [id])
    }

    func reorder(ids: [String]) async throws {
        for (index, id) in ids.enumerated() {
            try db.executeStatement(
                "UPDATE folders SET position = ?, updated_at = ? WHERE id = ?",
                params: [index, Date().iso8601String, id]
            )
        }
    }
}
