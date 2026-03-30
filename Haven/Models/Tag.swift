import Foundation

struct Tag: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var name: String
    let createdAt: Date

    init(id: String = UUID().uuidString, name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
