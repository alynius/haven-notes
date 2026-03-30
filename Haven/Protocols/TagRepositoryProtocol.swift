import Foundation

protocol TagRepositoryProtocol {
    func fetchAll() async throws -> [Tag]
    func findOrCreate(name: String) async throws -> Tag
    func delete(id: String) async throws
    func fetchTags(for noteID: String) async throws -> [Tag]
    func addTag(noteID: String, tagID: String) async throws
    func removeTag(noteID: String, tagID: String) async throws
}
