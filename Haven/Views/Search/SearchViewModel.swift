import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [Note] = []
    @Published var isSearching = false

    private let noteRepo: NoteRepositoryProtocol
    private var searchTask: Task<Void, Never>?

    init(noteRepo: NoteRepositoryProtocol) {
        self.noteRepo = noteRepo
    }

    func search() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            isSearching = false
            return
        }

        searchTask?.cancel()
        searchTask = Task {
            isSearching = true
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms debounce
            guard !Task.isCancelled else { return }

            do {
                results = try await noteRepo.search(query: trimmed)
            } catch {
                // Fallback: fetch all and filter client-side
                do {
                    let all = try await noteRepo.fetchAll()
                    let q = trimmed.lowercased()
                    results = all.filter {
                        $0.title.lowercased().contains(q) ||
                        $0.bodyPlaintext.lowercased().contains(q)
                    }
                } catch {
                    results = []
                }
            }
            isSearching = false
        }
    }

    func clearSearch() {
        query = ""
        results = []
        isSearching = false
    }
}
