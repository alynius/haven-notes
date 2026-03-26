import Foundation

struct WikiLink: Equatable, Codable, Hashable {
    let sourceNoteID: String
    let targetNoteID: String
    let linkText: String
}
