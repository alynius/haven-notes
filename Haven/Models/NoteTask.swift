import Foundation

struct NoteTask: Identifiable, Equatable, Codable, Hashable {
    let id: String
    let noteID: String
    var text: String
    var isCompleted: Bool
    var position: Int
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        noteID: String,
        text: String = "",
        isCompleted: Bool = false,
        position: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.noteID = noteID
        self.text = text
        self.isCompleted = isCompleted
        self.position = position
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
