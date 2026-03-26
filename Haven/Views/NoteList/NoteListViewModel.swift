import SwiftUI

@MainActor
final class NoteListViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let noteRepo: NoteRepositoryProtocol

    init(noteRepo: NoteRepositoryProtocol) {
        self.noteRepo = noteRepo
    }

    func loadNotes() async {
        isLoading = true
        do {
            notes = try await noteRepo.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createNote() async -> String? {
        do {
            let note = try await noteRepo.create(title: "", bodyHTML: "")
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
}
