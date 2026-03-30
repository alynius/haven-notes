import SwiftUI
import Combine

@MainActor
final class NoteEditorViewModel: ObservableObject {
    @Published var note: Note
    @Published var tasks: [NoteTask] = []
    @Published var tags: [Tag] = []
    @Published var allTags: [Tag] = []
    @Published var backlinks: [Note] = []
    @Published var autocompleteSuggestions: [Note] = []
    @Published var showAutocomplete = false
    @Published var isSaving = false
    @Published var isLoaded = false
    @Published var errorMessage: String?

    let speechRecognizer = SpeechRecognizer()

    private let noteRepo: NoteRepositoryProtocol
    private let taskRepo: TaskRepositoryProtocol
    private let tagRepo: TagRepositoryProtocol
    private let wikiLinkParser: WikiLinkParser
    private var autosaveTask: Task<Void, Never>?

    init(note: Note, noteRepo: NoteRepositoryProtocol, taskRepo: TaskRepositoryProtocol, tagRepo: TagRepositoryProtocol, wikiLinkParser: WikiLinkParser) {
        self.note = note
        self.noteRepo = noteRepo
        self.taskRepo = taskRepo
        self.tagRepo = tagRepo
        self.wikiLinkParser = wikiLinkParser
    }

    func resolveWikiLink(title: String) async -> Note? {
        try? await noteRepo.resolveWikiLink(title: title)
    }

    func load() async {
        do {
            // Load the actual note from DB if it exists (for existing notes)
            if let existing = try await noteRepo.fetchByID(note.id) {
                note = existing
            }
            tasks = try await taskRepo.fetchTasks(for: note.id)
            tags = try await tagRepo.fetchTags(for: note.id)
            allTags = try await tagRepo.fetchAll()
            backlinks = try await noteRepo.fetchBacklinks(for: note.id)
            isLoaded = true
        } catch {
            errorMessage = error.localizedDescription
            isLoaded = true
        }
    }

    func updateTitle(_ title: String) {
        note.title = title
        note.updatedAt = Date()
        scheduleAutosave()
    }

    func updateBody(_ markdown: String) {
        note.bodyHTML = markdown  // Raw markdown stored in bodyHTML field for DB compat
        note.bodyPlaintext = MarkdownStripper.stripMarkdown(markdown)
        note.updatedAt = Date()
        scheduleAutosave()

        // Check for wiki link autocomplete
        checkForAutocomplete(in: markdown)
    }

    func save() async {
        isSaving = true
        do {
            try await noteRepo.upsert(note)
            hasBeenSavedToDB = true
            try await noteRepo.rebuildLinks(for: note.id, bodyHTML: note.bodyHTML)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func addTask(text: String) async {
        do {
            await ensureNoteSaved()
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

    func addTag(name: String) async {
        do {
            // Ensure the note exists in DB before linking tags
            await ensureNoteSaved()
            let tag = try await tagRepo.findOrCreate(name: name)
            try await tagRepo.addTag(noteID: note.id, tagID: tag.id)
            tags = try await tagRepo.fetchTags(for: note.id)
            allTags = try await tagRepo.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeTag(tagID: String) async {
        do {
            try await tagRepo.removeTag(noteID: note.id, tagID: tagID)
            tags = try await tagRepo.fetchTags(for: note.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectAutocompleteSuggestion(_ suggestion: Note) {
        // Replace the partial [[query with [[SuggestionTitle]]
        let linkText = "[[" + suggestion.title + "]]"
        if let lastOpen = note.bodyHTML.range(of: "[[", options: .backwards) {
            note.bodyHTML = String(note.bodyHTML[..<lastOpen.lowerBound]) + linkText
            note.bodyPlaintext = MarkdownStripper.stripMarkdown(note.bodyHTML)
            note.updatedAt = Date()
            scheduleAutosave()
        }
        showAutocomplete = false
        autocompleteSuggestions = []
    }

    func insertDictatedText(_ text: String) {
        guard !text.isEmpty else { return }
        if note.bodyHTML.isEmpty {
            note.bodyHTML = text
        } else {
            note.bodyHTML += "\n\n" + text
        }
        note.bodyPlaintext = MarkdownStripper.stripMarkdown(note.bodyHTML)
        note.updatedAt = Date()
        scheduleAutosave()
    }

    // MARK: - Private

    /// Ensure the note exists in the database (for new notes that haven't been saved yet).
    private var hasBeenSavedToDB = false
    private func ensureNoteSaved() async {
        guard !hasBeenSavedToDB else { return }
        do {
            if try await noteRepo.fetchByID(note.id) == nil {
                // Save the current note to DB so tags/tasks can reference it
                await save()
            }
            hasBeenSavedToDB = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scheduleAutosave() {
        guard isLoaded else { return }  // Don't save until note is loaded from DB
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
