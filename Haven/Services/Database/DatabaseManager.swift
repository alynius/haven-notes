import Foundation
import SQLite3

final class DatabaseManager {
    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.haven.database", qos: .userInitiated)

    static let shared = DatabaseManager()

    private init() {}

    // MARK: - Connection

    func open() throws {
        let fileURL = try FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(HavenConstants.Database.fileName)

        // Use SQLITE_OPEN_FULLMUTEX for thread-safe serialized mode
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(fileURL.path, &db, flags, nil) == SQLITE_OK else {
            throw DatabaseError.cannotOpen
        }

        // Enable WAL mode for better concurrent read performance
        execute("PRAGMA journal_mode = WAL")
        execute("PRAGMA foreign_keys = ON")
    }

    func close() {
        if let db = db {
            sqlite3_close(db)
        }
        db = nil
    }

    // MARK: - Execute (no results)

    @discardableResult
    func execute(_ sql: String) -> Bool {
        guard let db = db else { return false }
        var errorMessage: UnsafeMutablePointer<Int8>?
        let result = sqlite3_exec(db, sql, nil, nil, &errorMessage)
        if let errorMessage = errorMessage {
            sqlite3_free(errorMessage)
        }
        return result == SQLITE_OK
    }

    // MARK: - Prepared Statement Execution

    /// Execute a parameterized statement that does not return rows.
    func executeStatement(_ sql: String, params: [Any?] = []) throws {
        guard let db = db else { throw DatabaseError.notOpen }
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let error = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(error)
        }

        guard let stmt = statement else {
            throw DatabaseError.queryFailed("Statement was nil after successful prepare")
        }
        defer { sqlite3_finalize(stmt) }

        bindParams(statement: stmt, params: params)

        let stepResult = sqlite3_step(stmt)
        guard stepResult == SQLITE_DONE || stepResult == SQLITE_ROW else {
            let error = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(error)
        }
    }

    // MARK: - Query with Row Handler

    /// Run a query with a closure that processes each row.
    func query(_ sql: String, params: [Any?] = [], handler: (OpaquePointer) -> Void) throws {
        guard let db = db else { throw DatabaseError.notOpen }
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let error = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(error)
        }

        guard let stmt = statement else {
            throw DatabaseError.queryFailed("Statement was nil after successful prepare")
        }
        defer { sqlite3_finalize(stmt) }

        bindParams(statement: stmt, params: params)

        while sqlite3_step(stmt) == SQLITE_ROW {
            handler(stmt)
        }
    }

    // MARK: - Thread Safety

    /// Execute work. SQLite handles thread safety via SQLITE_OPEN_FULLMUTEX.
    func performSync<T>(_ work: () throws -> T) rethrows -> T {
        try work()
    }

    // MARK: - Schema

    func createTables() {
        let statements: [String] = [
            """
            CREATE TABLE IF NOT EXISTS notes (
                id TEXT PRIMARY KEY NOT NULL,
                title TEXT NOT NULL DEFAULT '',
                body_html TEXT NOT NULL DEFAULT '',
                body_plaintext TEXT NOT NULL DEFAULT '',
                is_pinned INTEGER NOT NULL DEFAULT 0,
                is_deleted INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
            """,
            "CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at)",
            "CREATE INDEX IF NOT EXISTS idx_notes_is_deleted ON notes(is_deleted)",
            "CREATE INDEX IF NOT EXISTS idx_notes_is_pinned ON notes(is_pinned)",

            // Standalone FTS5 table — managed manually by NoteRepository.updateFTS()
            // Using note_id column to link back to notes table instead of rowid
            "CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(note_id UNINDEXED, title, body_plaintext)",

            """
            CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY NOT NULL,
                note_id TEXT NOT NULL,
                text TEXT NOT NULL DEFAULT '',
                is_completed INTEGER NOT NULL DEFAULT 0,
                position INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
            )
            """,
            "CREATE INDEX IF NOT EXISTS idx_tasks_note_id ON tasks(note_id)",

            """
            CREATE TABLE IF NOT EXISTS links (
                source_note_id TEXT NOT NULL,
                target_note_id TEXT NOT NULL,
                link_text TEXT NOT NULL,
                PRIMARY KEY (source_note_id, target_note_id, link_text),
                FOREIGN KEY (source_note_id) REFERENCES notes(id) ON DELETE CASCADE,
                FOREIGN KEY (target_note_id) REFERENCES notes(id) ON DELETE CASCADE
            )
            """,
            "CREATE INDEX IF NOT EXISTS idx_links_target ON links(target_note_id)",

            """
            CREATE TABLE IF NOT EXISTS sync_log (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                entity_type TEXT NOT NULL,
                entity_id TEXT NOT NULL,
                operation TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                synced_at TEXT
            )
            """,
            "CREATE INDEX IF NOT EXISTS idx_sync_log_unsynced ON sync_log(synced_at) WHERE synced_at IS NULL",

            """
            CREATE TABLE IF NOT EXISTS app_settings (
                key TEXT PRIMARY KEY NOT NULL,
                value TEXT NOT NULL
            )
            """,
            "INSERT OR IGNORE INTO app_settings (key, value) VALUES ('sync_enabled', 'false')",
            "INSERT OR IGNORE INTO app_settings (key, value) VALUES ('sync_server_url', '')",
            "INSERT OR IGNORE INTO app_settings (key, value) VALUES ('last_sync_timestamp', '')",
            "INSERT OR IGNORE INTO app_settings (key, value) VALUES ('theme_mode', 'system')",

            // Folders
            """
            CREATE TABLE IF NOT EXISTS folders (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                position INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
            """,
            "CREATE INDEX IF NOT EXISTS idx_folders_position ON folders(position)",

            // Tags
            """
            CREATE TABLE IF NOT EXISTS tags (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL UNIQUE,
                created_at TEXT NOT NULL
            )
            """,
            "CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name)",

            // Note-Tag join table
            """
            CREATE TABLE IF NOT EXISTS note_tags (
                note_id TEXT NOT NULL,
                tag_id TEXT NOT NULL,
                PRIMARY KEY (note_id, tag_id),
                FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
                FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
            )
            """,
            "CREATE INDEX IF NOT EXISTS idx_note_tags_tag_id ON note_tags(tag_id)"
        ]

        for sql in statements {
            execute(sql)
        }

        runMigrations()
    }

    // MARK: - Migrations

    func runMigrations() {
        // Add folder_id column to notes table if it doesn't exist
        var hasColumn = false
        try? query("PRAGMA table_info(notes)") { stmt in
            let name = DatabaseManager.columnTextNonNull(stmt, 1)
            if name == "folder_id" { hasColumn = true }
        }
        if !hasColumn {
            execute("ALTER TABLE notes ADD COLUMN folder_id TEXT REFERENCES folders(id) ON DELETE SET NULL")
            execute("CREATE INDEX IF NOT EXISTS idx_notes_folder_id ON notes(folder_id)")
        }
    }

    // MARK: - Helpers

    /// Convenience to read a nullable TEXT column.
    static func columnText(_ stmt: OpaquePointer, _ index: Int32) -> String? {
        guard let cString = sqlite3_column_text(stmt, index) else { return nil }
        return String(cString: cString)
    }

    /// Convenience to read a non-null TEXT column with a fallback.
    static func columnTextNonNull(_ stmt: OpaquePointer, _ index: Int32) -> String {
        columnText(stmt, index) ?? ""
    }

    // MARK: - Private

    private func bindParams(statement: OpaquePointer, params: [Any?]) {
        for (index, param) in params.enumerated() {
            let bindIndex = Int32(index + 1)
            if param == nil {
                sqlite3_bind_null(statement, bindIndex)
            } else if let value = param as? String {
                sqlite3_bind_text(statement, bindIndex, (value as NSString).utf8String, -1,
                                  unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            } else if let value = param as? Int {
                sqlite3_bind_int64(statement, bindIndex, Int64(value))
            } else if let value = param as? Int64 {
                sqlite3_bind_int64(statement, bindIndex, value)
            } else if let value = param as? Double {
                sqlite3_bind_double(statement, bindIndex, value)
            } else if let value = param as? Bool {
                sqlite3_bind_int(statement, bindIndex, value ? 1 : 0)
            }
        }
    }
}

// MARK: - DatabaseError

enum DatabaseError: Error, LocalizedError {
    case cannotOpen
    case notOpen
    case queryFailed(String)
    case notFound

    var errorDescription: String? {
        switch self {
        case .cannotOpen: return "Cannot open database"
        case .notOpen: return "Database not open"
        case .queryFailed(let msg): return "Query failed: \(msg)"
        case .notFound: return "Record not found"
        }
    }
}
