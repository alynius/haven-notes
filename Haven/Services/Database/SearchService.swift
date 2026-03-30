import Foundation
import SQLite3

final class SearchService {
    private let db: DatabaseManager

    init(db: DatabaseManager = .shared) {
        self.db = db
    }

    /// Search notes using FTS5. Returns matching notes ordered by relevance.
    /// The query is tokenized and each term gets a prefix wildcard for partial matching.
    func search(query: String, limit: Int = HavenConstants.maxSearchResults) throws -> [Note] {
        let sanitized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { return [] }

        return try db.performSync {
            // Build FTS5 query: each word gets a trailing * for prefix matching
            let ftsQuery = sanitized
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .map { self.escapeFTSToken($0) + "*" }
                .joined(separator: " ")

            let sql = """
                SELECT n.id, n.title, n.body_html, n.body_plaintext,
                       n.is_pinned, n.is_deleted, n.created_at, n.updated_at
                FROM \(HavenConstants.Database.notesFTSTable) fts
                JOIN \(HavenConstants.Database.notesTable) n ON n.id = fts.note_id
                WHERE fts MATCH ? AND n.is_deleted = 0
                ORDER BY rank
                LIMIT ?
                """

            var notes: [Note] = []
            try self.db.query(sql, params: [ftsQuery, limit]) { stmt in
                notes.append(self.noteFromRow(stmt))
            }
            return notes
        }
    }

    /// Search and return matching notes with a snippet of the matching context.
    /// Returns tuples of (note, snippet).
    func searchWithSnippets(
        query: String,
        limit: Int = HavenConstants.maxSearchResults
    ) throws -> [(note: Note, snippet: String)] {
        let sanitized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { return [] }

        return try db.performSync {
            let ftsQuery = sanitized
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .map { self.escapeFTSToken($0) + "*" }
                .joined(separator: " ")

            // snippet(table, column_index, before_match, after_match, trailing, max_tokens)
            let sql = """
                SELECT n.id, n.title, n.body_html, n.body_plaintext,
                       n.is_pinned, n.is_deleted, n.created_at, n.updated_at,
                       snippet(\(HavenConstants.Database.notesFTSTable), 1, '**', '**', '...', 32)
                FROM \(HavenConstants.Database.notesFTSTable) fts
                JOIN \(HavenConstants.Database.notesTable) n ON n.id = fts.note_id
                WHERE fts MATCH ? AND n.is_deleted = 0
                ORDER BY rank
                LIMIT ?
                """

            var results: [(note: Note, snippet: String)] = []
            try self.db.query(sql, params: [ftsQuery, limit]) { stmt in
                let note = self.noteFromRow(stmt)
                let snippet = DatabaseManager.columnTextNonNull(stmt, 8)
                results.append((note: note, snippet: snippet))
            }
            return results
        }
    }

    /// Rebuild the entire FTS index from the notes table.
    /// Useful after bulk imports or data migrations.
    func rebuildIndex() throws {
        try db.performSync {
            // Clear existing FTS content
            try self.db.executeStatement(
                "DELETE FROM \(HavenConstants.Database.notesFTSTable)"
            )

            // Re-populate from the notes table
            let sql = """
                INSERT INTO \(HavenConstants.Database.notesFTSTable)(note_id, title, body_plaintext)
                SELECT id, title, body_plaintext
                FROM \(HavenConstants.Database.notesTable)
                WHERE is_deleted = 0
                """
            try self.db.executeStatement(sql)
        }
    }

    // MARK: - Private

    private func noteFromRow(_ stmt: OpaquePointer) -> Note {
        Note(
            id: DatabaseManager.columnTextNonNull(stmt, 0),
            title: DatabaseManager.columnTextNonNull(stmt, 1),
            bodyHTML: DatabaseManager.columnTextNonNull(stmt, 2),
            bodyPlaintext: DatabaseManager.columnTextNonNull(stmt, 3),
            isPinned: sqlite3_column_int(stmt, 4) == 1,
            isDeleted: sqlite3_column_int(stmt, 5) == 1,
            createdAt: Date(iso8601String: DatabaseManager.columnTextNonNull(stmt, 6)) ?? Date(),
            updatedAt: Date(iso8601String: DatabaseManager.columnTextNonNull(stmt, 7)) ?? Date()
        )
    }

    /// Escape special FTS5 characters in a search token.
    private func escapeFTSToken(_ token: String) -> String {
        // FTS5 special characters that need quoting: " and *
        // Wrap in double quotes if the token contains special chars
        let specialChars = CharacterSet(charactersIn: "\"*():-^")
        if token.unicodeScalars.contains(where: { specialChars.contains($0) }) {
            let escaped = token.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return token
    }
}
