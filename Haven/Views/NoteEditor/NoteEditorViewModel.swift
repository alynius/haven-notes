import SwiftUI
import Combine

@MainActor
final class NoteEditorViewModel: ObservableObject {
    @Published var note: Note
    @Published var tasks: [NoteTask] = []
    @Published var backlinks: [Note] = []
    @Published var autocompleteSuggestions: [Note] = []
    @Published var showAutocomplete = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let noteRepo: NoteRepositoryProtocol
    private let taskRepo: TaskRepositoryProtocol
    private let wikiLinkParser: WikiLinkParser
    private var autosaveTask: Task<Void, Never>?

    init(note: Note, noteRepo: NoteRepositoryProtocol, taskRepo: TaskRepositoryProtocol, wikiLinkParser: WikiLinkParser) {
        self.note = note
        self.noteRepo = noteRepo
        self.taskRepo = taskRepo
        self.wikiLinkParser = wikiLinkParser
    }

    func load() async {
        do {
            tasks = try await taskRepo.fetchTasks(for: note.id)
            backlinks = try await noteRepo.fetchBacklinks(for: note.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateTitle(_ title: String) {
        note.title = title
        note.updatedAt = Date()
        scheduleAutosave()
    }

    func updateBody(_ html: String) {
        note.bodyHTML = html
        note.bodyPlaintext = HTMLSanitizer.stripHTML(html)
        note.updatedAt = Date()
        scheduleAutosave()

        // Check for wiki link autocomplete
        checkForAutocomplete(in: note.bodyPlaintext)
    }

    func save() async {
        isSaving = true
        do {
            try await noteRepo.update(note)
            try await noteRepo.rebuildLinks(for: note.id, bodyHTML: note.bodyHTML)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func addTask(text: String) async {
        do {
            let task = try await taskRepo.create(noteID: note.id, text: text, position: tasks.count)
            tasks.append(task)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleTask(_ taskID: String) async {
        do {
            try await taskRepo.toggleComplete(id: taskID)
            tasks = try await taskRepo.fetchTasks(for: note.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(_ taskID: String) async {
        do {
            try await taskRepo.delete(id: taskID)
            tasks.removeAll { $0.id == taskID }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectAutocompleteSuggestion(_ suggestion: Note) {
        showAutocomplete = false
        autocompleteSuggestions = []
    }

    // MARK: - Private

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(HavenConstants.autosaveDebounceSeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await save()
        }
    }

    private func checkForAutocomplete(in text: String) {
        // Simple check: look for [[ without closing ]]
        guard let lastOpen = text.range(of: "[[", options: .backwards) else {
            showAutocomplete = false
            return
        }

        let afterOpen = String(text[lastOpen.upperBound...])
        if afterOpen.contains("]]") {
            showAutocomplete = false
            return
        }

        let query = afterOpen.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            showAutocomplete = false
            return
        }

        Task {
            do {
                autocompleteSuggestions = try await noteRepo.autocompleteTitles(query: query, limit: HavenConstants.autocompleteSuggestionLimit)
                showAutocomplete = !autocompleteSuggestions.isEmpty
            } catch {
                showAutocomplete = false
            }
        }
    }
}
