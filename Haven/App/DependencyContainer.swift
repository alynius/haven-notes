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

    lazy var searchService: SearchService = {
        SearchService(db: databaseManager)
    }()

    // MARK: - Sync

    lazy var syncManager: SyncManager = {
        SyncManager(db: databaseManager, noteRepo: noteRepository, taskRepo: taskRepository)
    }()

    // MARK: - Subscription

    lazy var subscriptionManager: SubscriptionManager = {
        SubscriptionManager()
    }()

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
