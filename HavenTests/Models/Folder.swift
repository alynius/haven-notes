import Foundation

struct Folder: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var name: String
    var position: Int
    let createdAt: Date
    var updatedAt: Date

    init(id: String = UUID().uuidString, name: String, position: Int = 0,
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.position = position
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
