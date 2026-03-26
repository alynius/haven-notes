import Foundation

struct Note: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var title: String
    var bodyHTML: String
    var bodyPlaintext: String
    var isPinned: Bool
    var isDeleted: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String = "",
        bodyHTML: String = "",
        bodyPlaintext: String = "",
        isPinned: Bool = false,
        isDeleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.bodyHTML = bodyHTML
        self.bodyPlaintext = bodyPlaintext
        self.isPinned = isPinned
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
