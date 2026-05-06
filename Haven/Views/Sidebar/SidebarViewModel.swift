import SwiftUI

@MainActor
final class SidebarViewModel: ObservableObject {
    @Published var folders: [Folder] = []
    @Published var tags: [Tag] = []
    @Published var folderNoteCounts: [String: Int] = [:]
    @Published var tagNoteCounts: [String: Int] = [:]
    @Published var totalNoteCount: Int = 0
    @Published var errorMessage: String?
    @Published var isCreatingFolder = false
    @Published var newFolderName = ""

    private let folderRepo: FolderRepositoryProtocol
    private let tagRepo: TagRepositoryProtocol
    private let noteRepo: NoteRepositoryProtocol

    init(folderRepo: FolderRepositoryProtocol, tagRepo: TagRepositoryProtocol, noteRepo: NoteRepositoryProtocol) {
        self.folderRepo = folderRepo
        self.tagRepo = tagRepo
        self.noteRepo = noteRepo
    }

    func loadAll() async {
        do {
            folders = try await folderRepo.fetchAll()
            tags = try await tagRepo.fetchAll()
            totalNoteCount = await noteRepo.countAll()
            folderNoteCounts = await noteRepo.countByFolder()
            tagNoteCounts = await noteRepo.countByTag()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createFolder() async {
        let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            let _ = try await folderRepo.create(name: name)
            newFolderName = ""
            isCreatingFolder = false
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func renameFolder(id: String, name: String) async {
        do {
            try await folderRepo.rename(id: id, name: name)
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setFolderColor(id: String, color: String?) async {
        do {
            try await folderRepo.setColor(id: id, color: color)
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteFolder(id: String) async {
        do {
            try await folderRepo.delete(id: id)
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTag(id: String) async {
        do {
            try await tagRepo.delete(id: id)
            await loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Optimistically reorder folders in-memory and persist new positions.
    /// Failed save surfaces via errorMessage; UI keeps the new order until next loadAll().
    func reorderFolders(from source: IndexSet, to destination: Int) async {
        var newOrder = folders
        newOrder.move(fromOffsets: source, toOffset: destination)
        folders = newOrder
        do {
            try await folderRepo.reorder(ids: newOrder.map(\.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
