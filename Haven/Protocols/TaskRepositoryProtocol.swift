import Foundation

protocol TaskRepositoryProtocol {
    func create(noteID: String, text: String, position: Int) async throws -> NoteTask
    func fetchTasks(for noteID: String) async throws -> [NoteTask]
    func update(_ task: NoteTask) async throws
    func toggleComplete(id: String) async throws
    func delete(id: String) async throws
    func reorder(noteID: String, taskIDs: [String]) async throws
}
