import Foundation

struct SyncLogEntry: Identifiable, Equatable, Codable {
    let id: Int
    let entityType: String
    let entityID: String
    let operation: String
    let timestamp: Date
    var syncedAt: Date?
}
