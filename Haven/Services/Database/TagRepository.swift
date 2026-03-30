import Foundation
import SQLite3

final class TagRepository: TagRepositoryProtocol {
    private let db: DatabaseManager

    init(db: DatabaseManager) { self.db = db }

    func fetchAll() async throws -> [Tag] {
        var tags: [Tag] = []
        try db.query("SELECT id, name, created_at FROM tags ORDER BY name ASC") { stmt in
            tags.append(Tag(
                id: DatabaseManager.columnTextNonNull(stmt, 0),
                name: DatabaseManager.columnTextNonNull(stmt, 1),
                createdAt: Date(iso8601String: DatabaseManager.columnTextNonNull(stmt, 2)) ?? Date()
            ))
        }
        return tags
    }

    func findOrCreate(name: String) async throws -> Tag {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // Try to find existing
        var existing: Tag?
        try db.query("SELECT id, name, created_at FROM tags WHERE name = ? LIMIT 1", params: [trimmed]) { stmt in
            existing = Tag(
                id: DatabaseManager.columnTextNonNull(stmt, 0),
                name: DatabaseManager.columnTextNonNull(stmt, 1),
                createdAt: Date(iso8601String: DatabaseManager.columnTextNonNull(stmt, 2)) ?? Date()
            )
        }
        if let tag = existing { return tag }
        // Create new
        let tag = Tag(name: trimmed)
        try db.executeStatement(
            "INSERT INTO tags (id, name, created_at) VALUES (?, ?, ?)",
            params: [tag.id, tag.name, tag.createdAt.iso8601String]
        )
        return tag
    }

    func delete(id: String) async throws {
        // ON DELETE CASCADE handles note_tags cleanup
        try db.executeStatement("DELETE FROM tags WHERE id = ?", params: [id])
    }

    func fetchTags(for noteID: String) async throws -> [Tag] {
        var tags: [Tag] = []
        let sql = """
            SELECT t.id, t.name, t.created_at FROM tags t
            JOIN note_tags nt ON nt.tag_id = t.id
            WHERE nt.note_id = ?
            ORDER BY t.name ASC
            """
        try db.query(sql, params: [noteID]) { stmt in
            tags.append(Tag(
                id: DatabaseManager.columnTextNonNull(stmt, 0),
                name: DatabaseManager.columnTextNonNull(stmt, 1),
                createdAt: Date(iso8601String: DatabaseManager.columnTextNonNull(stmt, 2)) ?? Date()
            ))
        }
        return tags
    }

    func addTag(noteID: String, tagID: String) async throws {
        try db.executeStatement(
            "INSERT OR IGNORE INTO note_tags (note_id, tag_id) VALUES (?, ?)",
            params: [noteID, tagID]
        )
    }

    func removeTag(noteID: String, tagID: String) async throws {
        try db.executeStatement(
            "DELETE FROM note_tags WHERE note_id = ? AND tag_id = ?",
            params: [noteID, tagID]
        )
    }
}
