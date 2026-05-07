import Foundation

struct Folder: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var name: String
    var position: Int
    /// Hex string for the folder accent color (e.g. "#F97316"), or nil for the default.
    var color: String?
    let createdAt: Date
    var updatedAt: Date

    init(id: String = UUID().uuidString, name: String, position: Int = 0,
         color: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.position = position
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
