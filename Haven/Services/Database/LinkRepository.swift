import Foundation
import SQLite3

final class LinkRepository {
    private let db: DatabaseManager

    init(db: DatabaseManager = .shared) {
        self.db = db
    }

    // MARK: - Fetch Outgoing Links

    /// Returns all wiki links originating from the given note.
    func fetchLinks(from noteID: String) throws -> [WikiLink] {
        try db.performSync {
            let sql = """
                SELECT source_note_id, target_note_id, link_text
                FROM \(HavenConstants.Database.linksTable)
                WHERE source_note_id = ?
                """
            var links: [WikiLink] = []
            try self.db.query(sql, params: [noteID]) { stmt in
                links.append(self.linkFromRow(stmt))
            }
            return links
        }
    }

    // MARK: - Fetch Backlinks

    /// Returns all wiki links pointing to the given note.
    func fetchBacklinks(to noteID: String) throws -> [WikiLink] {
        try db.performSync {
            let sql = """
                SELECT source_note_id, target_note_id, link_text
                FROM \(HavenConstants.Database.linksTable)
                WHERE target_note_id = ?
                """
            var links: [WikiLink] = []
            try self.db.query(sql, params: [noteID]) { stmt in
                links.append(self.linkFromRow(stmt))
            }
            return links
        }
    }

    // MARK: - Rebuild Links

    /// Deletes all existing outgoing links from a note and inserts new ones.
    /// - Parameters:
    ///   - noteID: The source note whose links are being rebuilt.
    ///   - targets: An array of resolved (targetID, linkText) pairs.
    func rebuildLinks(for noteID: String, targets: [(targetID: String, text: String)]) throws {
        try db.performSync {
            // Remove all existing outgoing links
            let deleteSql = "DELETE FROM \(HavenConstants.Database.linksTable) WHERE source_note_id = ?"
            try self.db.executeStatement(deleteSql, params: [noteID])

            // Insert each resolved link
            let insertSql = """
                INSERT OR IGNORE INTO \(HavenConstants.Database.linksTable)
                (source_note_id, target_note_id, link_text)
                VALUES (?, ?, ?)
                """
            for target in targets {
                try self.db.executeStatement(insertSql, params: [noteID, target.targetID, target.text])
            }
        }
    }

    // MARK: - Delete Links

    /// Deletes all outgoing links from the given note.
    func deleteLinks(from noteID: String) throws {
        try db.performSync {
            let sql = "DELETE FROM \(HavenConstants.Database.linksTable) WHERE source_note_id = ?"
            try self.db.executeStatement(sql, params: [noteID])
        }
    }

    // MARK: - Private

    private func linkFromRow(_ stmt: OpaquePointer) -> WikiLink {
        WikiLink(
            sourceNoteID: DatabaseManager.columnTextNonNull(stmt, 0),
            targetNoteID: DatabaseManager.columnTextNonNull(stmt, 1),
            linkText: DatabaseManager.columnTextNonNull(stmt, 2)
        )
    }
}
