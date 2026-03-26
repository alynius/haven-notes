import Foundation

enum HavenConstants {
    static let appName = "Haven"
    static let defaultSyncIntervalSeconds: TimeInterval = 300 // 5 minutes
    static let maxNoteTitleLength = 500
    static let maxSearchResults = 50
    static let autocompleteSuggestionLimit = 10
    static let autosaveDebounceSeconds: TimeInterval = 1.0

    enum Database {
        static let fileName = "haven.sqlite"
        static let notesTable = "notes"
        static let tasksTable = "tasks"
        static let linksTable = "links"
        static let syncLogTable = "sync_log"
        static let settingsTable = "app_settings"
        static let notesFTSTable = "notes_fts"
    }

    enum Subscription {
        static let groupID = "haven_pro"
    }
}
