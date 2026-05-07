import Foundation

protocol NoteRepositoryProtocol {
    func create(title: String, bodyHTML: String, folderID: String?) async throws -> Note
    func fetchByID(_ id: String) async throws -> Note?
    func fetchAll() async throws -> [Note]
    func countAll() async -> Int
    func countByFolder() async -> [String: Int]
    func countByTag() async -> [String: Int]
    func update(_ note: Note) async throws
    func upsert(_ note: Note) async throws
    func softDelete(id: String) async throws
    func purgeDeleted(olderThan date: Date) async throws
    func togglePin(id: String) async throws
    func search(query: String) async throws -> [Note]
    func resolveWikiLink(title: String) async throws -> Note?
    func autocompleteTitles(query: String, limit: Int) async throws -> [Note]
    func fetchBacklinks(for noteID: String) async throws -> [Note]
    func rebuildLinks(for noteID: String, bodyHTML: String) async throws
    func fetchByFolder(folderID: String?) async throws -> [Note]
    func fetchByTag(tagID: String) async throws -> [Note]
    func moveToFolder(noteID: String, folderID: String?) async throws
    func reorderNotes(ids: [String]) async throws
}
