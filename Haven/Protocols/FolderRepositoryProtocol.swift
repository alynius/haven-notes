import Foundation

protocol FolderRepositoryProtocol {
    func fetchAll() async throws -> [Folder]
    func create(name: String) async throws -> Folder
    func rename(id: String, name: String) async throws
    func delete(id: String) async throws
    func reorder(ids: [String]) async throws
}
