import SwiftUI
import SQLite3

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var themeMode: String = "system"
    @Published var noteCount: Int = 0

    private let noteRepo: NoteRepositoryProtocol
    private let db: DatabaseManager

    init(noteRepo: NoteRepositoryProtocol, db: DatabaseManager) {
        self.noteRepo = noteRepo
        self.db = db
    }

    func load() async {
        do {
            let notes = try await noteRepo.fetchAll()
            noteCount = notes.count
        } catch {
            noteCount = 0
        }

        // Load theme setting
        try? db.query("SELECT value FROM app_settings WHERE key = 'theme_mode'") { stmt in
            themeMode = String(cString: sqlite3_column_text(stmt, 0))
        }
    }

    func setThemeMode(_ mode: String) {
        themeMode = mode
        try? db.executeStatement(
            "UPDATE app_settings SET value = ? WHERE key = 'theme_mode'",
            params: [mode]
        )
    }
}
