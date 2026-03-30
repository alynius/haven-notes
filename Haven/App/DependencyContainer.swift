import Foundation

@MainActor
final class DependencyContainer: ObservableObject {

    // MARK: - Database

    let databaseManager: DatabaseManager = .shared

    // MARK: - Repositories

    lazy var noteRepository: NoteRepository = {
        NoteRepository(db: databaseManager)
    }()

    lazy var taskRepository: TaskRepository = {
        TaskRepository(db: databaseManager)
    }()

    lazy var linkRepository: LinkRepository = {
        LinkRepository(db: databaseManager)
    }()

    lazy var folderRepository: FolderRepository = FolderRepository(db: databaseManager)

    lazy var tagRepository: TagRepository = TagRepository(db: databaseManager)

    lazy var searchService: SearchService = {
        SearchService(db: databaseManager)
    }()

    // MARK: - Encryption

    lazy var encryptionService: EncryptionService = {
        let service = EncryptionService()
        // Try to load existing key from Keychain
        _ = service.loadKeyFromKeychain()
        return service
    }()

    // MARK: - Sync

    lazy var syncManager: SyncManager = {
        SyncManager(db: databaseManager, noteRepo: noteRepository, taskRepo: taskRepository, encryptionService: encryptionService)
    }()

    // MARK: - Subscription

    lazy var subscriptionManager: SubscriptionManager = {
        SubscriptionManager()
    }()

    // MARK: - Import

    lazy var notionImporter: NotionImporter = NotionImporter(noteRepo: noteRepository)

    // MARK: - Security

    lazy var biometricService: BiometricService = BiometricService()

    // MARK: - Daily Note

    lazy var dailyNoteService: DailyNoteService = DailyNoteService(noteRepo: noteRepository)

    // MARK: - Editor

    lazy var wikiLinkParser: WikiLinkParser = {
        WikiLinkParser()
    }()

    // MARK: - Initialization

    func initialize() throws {
        try databaseManager.open()
        databaseManager.createTables()
    }
}
