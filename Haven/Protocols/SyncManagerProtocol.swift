import Foundation

enum SyncStatus: Equatable {
    case idle
    case syncing
    case error(String)
    case disabled
}

@MainActor
protocol SyncManagerProtocol: AnyObject {
    var status: SyncStatus { get }
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) async throws
    func configure(serverURL: URL, authToken: String) async throws
    func pushChanges() async throws
    func pullChanges() async throws
    func sync() async throws
    func recordChange(entityType: String, entityID: String, operation: String) async throws
    func markSynced(ids: [Int]) async throws
    func fetchUnsyncedChanges() async throws -> [SyncLogEntry]
    func resolveConflict(local: Note, remote: Note) -> Note
}
