import Foundation
import SQLite3

final class NoteRepository: NoteRepositoryProtocol {
    private let db: DatabaseManager

    init(db: DatabaseManager = .shared) {
        self.db = db
    }

    // MARK: - Create

    func create(title: String, bodyHTML: String, folderID: String? = nil) async throws -> Note {
        let note = Note(
            title: title,
            bodyHTML: bodyHTML,
            bodyPlaintext: HTMLSanitizer.stripHTML(bodyHTML),
            folderID: folderID
        )

        try db.performSync {
            let sql = """
                INSERT INTO \(HavenConstants.Database.notesTable)
                (id, title, body_html, body_plaintext, is_pinned, is_deleted, folder_id, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """
            try self.db.executeStatement(sql, params: [
                note.id,
                note.title,
                note.bodyHTML,
                note.bodyPlaintext,
                note.isPinned ? 1 : 0,
                note.isDeleted ? 1 : 0,
                note.folderID,
                note.createdAt.iso8601String,
                note.updatedAt.iso8601String
            ])

            try self.updateFTS(noteID: note.id, title: note.title, plaintext: note.bodyPlaintext)
            try self.recordSyncChange(entityType: "note", entityID: note.id, operation: "insert")
        }

        return note
    }

    // MARK: - Fetch

    func fetchByID(_ id: String) async throws -> Note? {
        try db.performSync {
            let sql = "SELECT id, title, body_html, body_plaintext, is_pinned, is_deleted, created_at, updated_at, folder_id FROM \(HavenConstants.Database.notesTable) WHERE id = ?"
            var result: Note?
            try self.db.query(sql, params: [id]) { stmt in
                result = self.noteFromRow(stmt)
            }
            return result
        }
    }

    func fetchAll() async throws -> [Note] {
        try db.performSync {
            let sql = """
                SELECT id, title, body_html, body_plaintext, is_pinned, is_deleted, created_at, updated_at, folder_id
                FROM \(HavenConstants.Database.notesTable)
                WHERE is_deleted = 0
                ORDER BY is_pinned DESC, updated_at DESC
                """
            var notes: [Note] = []
            try self.db.query(sql) { stmt in
                notes.append(self.noteFromRow(stmt))
            }
            return notes
        }
    }

    // MARK: - Update

    func update(_ note: Note) async throws {
        let plaintext = HTMLSanitizer.stripHTML(note.bodyHTML)

        try db.performSync {
            let sql = """
                UPDATE \(HavenConstants.Database.notesTable)
                SET title = ?, body_html = ?, body_plaintext = ?, is_pinned = ?, is_deleted = ?, updated_at = ?
                WHERE id = ?
                """
            try self.db.executeStatement(sql, params: [
                note.title,
                note.bodyHTML,
                plaintext,
                note.isPinned ? 1 : 0,
                note.isDeleted ? 1 : 0,
                Date().iso8601String,
                note.id
            ])

            try self.updateFTS(noteID: note.id, title: note.title, plaintext: plaintext)
            try self.recordSyncChange(entityType: "note", entityID: note.id, operation: "update")
        }
    }

    /// Insert or replace — used by the editor to save both new and existing notes.
    func upsert(_ note: Note) async throws {
        let plaintext = MarkdownStripper.stripMarkdown(note.bodyHTML)

        try db.performSync {
            let sql = """
                INSERT INTO \(HavenConstants.Database.notesTable)
                (id, title, body_html, body_plaintext, is_pinned, is_deleted, folder_id, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    title = excluded.title,
                    body_html = excluded.body_html,
                    body_plaintext = excluded.body_plaintext,
                    is_pinned = excluded.is_pinned,
                    is_deleted = excluded.is_deleted,
                    folder_id = excluded.folder_id,
                    updated_at = excluded.updated_at
                """
            try self.db.executeStatement(sql, params: [
                note.id,
                note.title,
                note.bodyHTML,
                plaintext,
                note.isPinned ? 1 : 0,
                note.isDeleted ? 1 : 0,
                note.folderID,
                note.createdAt.iso8601String,
                Date().iso8601String
            ])

            try self.updateFTS(noteID: note.id, title: note.title, plaintext: plaintext)
            try self.recordSyncChange(entityType: "note", entityID: note.id, operation: "upsert")
        }
    }

    // MARK: - Soft Delete

    func softDelete(id: String) async throws {
        try db.performSync {
            let sql = """
                UPDATE \(HavenConstants.Database.notesTable)
                SET is_deleted = 1, updated_at = ?
                WHERE id = ?
                """
            try self.db.executeStatement(sql, params: [Date().iso8601String, id])
            try self.recordSyncChange(entityType: "note", entityID: id, operation: "delete")
        }
    }

    // MARK: - Purge

    func purgeDeleted(olderThan date: Date) async throws {
        try db.performSync {
            let sql = """
                DELETE FROM \(HavenConstants.Database.notesTable)
                WHERE is_deleted = 1 AND updated_at < ?
                """
            try self.db.executeStatement(sql, params: [date.iso8601String])
        }
    }

    // MARK: - Pin

    func togglePin(id: String) async throws {
        try db.performSync {
            let sql = """
                UPDATE \(HavenConstants.Database.notesTable)
                SET is_pinned = CASE WHEN is_pinned = 1 THEN 0 ELSE 1 END, updated_at = ?
                WHERE id = ?
                """
            try self.db.executeStatement(sql, params: [Date().iso8601String, id])
            try self.recordSyncChange(entityType: "note", entityID: id, operation: "update")
        }
    }

    // MARK: - Search (FTS5)

    func search(query: String) async throws -> [Note] {
        let sanitized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { return [] }

        // Use FTS5 MATCH; append * for prefix matching
        let ftsQuery = sanitized
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { "\($0)*" }
            .joined(separator: " ")

        let sql = """
            SELECT n.id, n.title, n.body_html, n.body_plaintext, n.is_pinned, n.is_deleted, n.created_at, n.updated_at, n.folder_id
            FROM \(HavenConstants.Database.notesFTSTable) fts
            JOIN \(HavenConstants.Database.notesTable) n ON n.id = fts.note_id
            WHERE fts MATCH ? AND n.is_deleted = 0
            ORDER BY rank
            LIMIT ?
            """
        var notes: [Note] = []
        try db.query(sql, params: [ftsQuery, HavenConstants.maxSearchResults]) { stmt in
            notes.append(self.noteFromRow(stmt))
        }
        return notes
    }

    // MARK: - Wiki Link Resolution

    func resolveWikiLink(title: String) async throws -> Note? {
        try db.performSync {
            let sql = """
                SELECT id, title, body_html, body_plaintext, is_pinned, is_deleted, created_at, updated_at, folder_id
                FROM \(HavenConstants.Database.notesTable)
                WHERE LOWER(title) = LOWER(?) AND is_deleted = 0
                LIMIT 1
                """
            var result: Note?
            try self.db.query(sql, params: [title]) { stmt in
                result = self.noteFromRow(stmt)
            }
            return result
        }
    }

    // MARK: - Autocomplete

    func autocompleteTitles(query: String, limit: Int) async throws -> [Note] {
        let sanitized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { return [] }

        return try db.performSync {
            let sql = """
                SELECT id, title, body_html, body_plaintext, is_pinned, is_deleted, created_at, updated_at, folder_id
                FROM \(HavenConstants.Database.notesTable)
                WHERE title LIKE ? AND is_deleted = 0
                ORDER BY updated_at DESC
                LIMIT ?
                """
            let pattern = "%\(sanitized)%"
            var notes: [Note] = []
            try self.db.query(sql, params: [pattern, limit]) { stmt in
                notes.append(self.noteFromRow(stmt))
            }
            return notes
        }
    }

    // MARK: - Backlinks

    func fetchBacklinks(for noteID: String) async throws -> [Note] {
        try db.performSync {
            let sql = """
                SELECT n.id, n.title, n.body_html, n.body_plaintext, n.is_pinned, n.is_deleted, n.created_at, n.updated_at, n.folder_id
                FROM \(HavenConstants.Database.linksTable) l
                JOIN \(HavenConstants.Database.notesTable) n ON n.id = l.source_note_id
                WHERE l.target_note_id = ? AND n.is_deleted = 0
                """
            var notes: [Note] = []
            try self.db.query(sql, params: [noteID]) { stmt in
                notes.append(self.noteFromRow(stmt))
            }
            return notes
        }
    }

    // MARK: - Rebuild Links

    func rebuildLinks(for noteID: String, bodyHTML: String) async throws {
        // bodyHTML now stores raw markdown — extract [[links]] directly
        let linkTargets = bodyHTML.wikiLinkTargets

        try db.performSync {
            // Delete existing outgoing links for this note
            let deleteSql = "DELETE FROM \(HavenConstants.Database.linksTable) WHERE source_note_id = ?"
            try self.db.executeStatement(deleteSql, params: [noteID])

            // Resolve each target and insert link (case-insensitive match)
            for target in linkTargets {
                let findSql = """
                    SELECT id FROM \(HavenConstants.Database.notesTable)
                    WHERE LOWER(title) = LOWER(?) AND is_deleted = 0
                    LIMIT 1
                    """
                var targetID: String?
                try self.db.query(findSql, params: [target]) { stmt in
                    targetID = DatabaseManager.columnTextNonNull(stmt, 0)
                }

                if let resolvedID = targetID, !resolvedID.isEmpty, resolvedID != noteID {
                    let insertSql = """
                        INSERT OR IGNORE INTO \(HavenConstants.Database.linksTable)
                        (source_note_id, target_note_id, link_text)
                        VALUES (?, ?, ?)
                        """
                    try self.db.executeStatement(insertSql, params: [noteID, resolvedID, target])
                }
            }
        }
    }

    // MARK: - Folder / Tag Queries

    func fetchByFolder(folderID: String?) async throws -> [Note] {
        try db.performSync {
            let sql: String
            let params: [Any?]
            if let folderID = folderID {
                sql = """
                    SELECT id, title, body_html, body_plaintext, is_pinned, is_deleted, created_at, updated_at, folder_id
                    FROM \(HavenConstants.Database.notesTable)
                    WHERE folder_id = ? AND is_deleted = 0
                    ORDER BY is_pinned DESC, updated_at DESC
                    """
                params = [folderID]
            } else {
                sql = """
                    SELECT id, title, body_html, body_plaintext, is_pinned, is_deleted, created_at, updated_at, folder_id
                    FROM \(HavenConstants.Database.notesTable)
                    WHERE folder_id IS NULL AND is_deleted = 0
                    ORDER BY is_pinned DESC, updated_at DESC
                    """
                params = []
            }
            var notes: [Note] = []
            try self.db.query(sql, params: params) { stmt in
                notes.append(self.noteFromRow(stmt))
            }
            return notes
        }
    }

    func fetchByTag(tagID: String) async throws -> [Note] {
        try db.performSync {
            let sql = """
                SELECT n.id, n.title, n.body_html, n.body_plaintext, n.is_pinned, n.is_deleted, n.created_at, n.updated_at, n.folder_id
                FROM \(HavenConstants.Database.notesTable) n
                JOIN \(HavenConstants.Database.noteTagsTable) nt ON nt.note_id = n.id
                WHERE nt.tag_id = ? AND n.is_deleted = 0
                ORDER BY n.is_pinned DESC, n.updated_at DESC
                """
            var notes: [Note] = []
            try self.db.query(sql, params: [tagID]) { stmt in
                notes.append(self.noteFromRow(stmt))
            }
            return notes
        }
    }

    func moveToFolder(noteID: String, folderID: String?) async throws {
        try db.performSync {
            let sql = """
                UPDATE \(HavenConstants.Database.notesTable)
                SET folder_id = ?, updated_at = ?
                WHERE id = ?
                """
            try self.db.executeStatement(sql, params: [folderID, Date().iso8601String, noteID])
            try self.recordSyncChange(entityType: "note", entityID: noteID, operation: "update")
        }
    }

    // MARK: - Private Helpers

    private func noteFromRow(_ stmt: OpaquePointer) -> Note {
        Note(
            id: DatabaseManager.columnTextNonNull(stmt, 0),
            title: DatabaseManager.columnTextNonNull(stmt, 1),
            bodyHTML: DatabaseManager.columnTextNonNull(stmt, 2),
            bodyPlaintext: DatabaseManager.columnTextNonNull(stmt, 3),
            isPinned: sqlite3_column_int(stmt, 4) == 1,
            isDeleted: sqlite3_column_int(stmt, 5) == 1,
            folderID: DatabaseManager.columnText(stmt, 8),
            createdAt: Date(iso8601String: DatabaseManager.columnTextNonNull(stmt, 6)) ?? Date(),
            updatedAt: Date(iso8601String: DatabaseManager.columnTextNonNull(stmt, 7)) ?? Date()
        )
    }

    private func updateFTS(noteID: String, title: String, plaintext: String) throws {
        // Standalone FTS5: delete old entry by note_id, then insert new one
        let deleteSQL = "DELETE FROM \(HavenConstants.Database.notesFTSTable) WHERE note_id = ?"
        try db.executeStatement(deleteSQL, params: [noteID])

        let insertSQL = "INSERT INTO \(HavenConstants.Database.notesFTSTable)(note_id, title, body_plaintext) VALUES (?, ?, ?)"
        try db.executeStatement(insertSQL, params: [noteID, title, plaintext])
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
