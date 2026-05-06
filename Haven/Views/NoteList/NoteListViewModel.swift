import SwiftUI

@MainActor
final class NoteListViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var folders: [String: String] = [:]  // folderID -> folderName
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let noteRepo: NoteRepositoryProtocol
    private let folderRepo: FolderRepositoryProtocol?
    var filter: NoteFilter

    init(noteRepo: NoteRepositoryProtocol, folderRepo: FolderRepositoryProtocol? = nil, filter: NoteFilter = .allNotes) {
        self.noteRepo = noteRepo
        self.folderRepo = folderRepo
        self.filter = filter
    }

    func loadNotes() async {
        isLoading = true
        do {
            switch filter {
            case .allNotes:
                notes = try await noteRepo.fetchAll()
            case .folder(let id, _):
                notes = try await noteRepo.fetchByFolder(folderID: id)
            case .tag(let id, _):
                notes = try await noteRepo.fetchByTag(tagID: id)
            }
            // Load folder names for display
            if let folderRepo = folderRepo {
                let allFolders = try await folderRepo.fetchAll()
                folders = Dictionary(uniqueKeysWithValues: allFolders.map { ($0.id, $0.name) })
            }

            // Share note count with widget via App Groups.
            // For .all filter, the loaded array already holds every non-deleted note, so we skip the extra COUNT query.
            let totalCount: Int
            if case .allNotes = filter {
                totalCount = notes.count
            } else {
                totalCount = await noteRepo.countAll()
            }
            UserDefaults(suiteName: HavenConstants.AppGroup.identifier)?
                .set(totalCount, forKey: HavenConstants.AppGroup.noteCountKey)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createNote() async -> String? {
        do {
            let folderID: String? = if case .folder(let id, _) = filter { id } else { nil }
            let note = try await noteRepo.create(title: "", bodyHTML: "", folderID: folderID)
            await loadNotes()
            return note.id
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func deleteNote(id: String) async {
        do {
            try await noteRepo.softDelete(id: id)
            await loadNotes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func togglePin(id: String) async {
        do {
            try await noteRepo.togglePin(id: id)
            await loadNotes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveNote(id: String, toFolderID folderID: String?) async {
        do {
            try await noteRepo.moveToFolder(noteID: id, folderID: folderID)
            await loadNotes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
