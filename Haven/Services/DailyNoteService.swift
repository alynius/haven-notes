import Foundation

final class DailyNoteService {
    private let noteRepo: NoteRepositoryProtocol

    init(noteRepo: NoteRepositoryProtocol) {
        self.noteRepo = noteRepo
    }

    /// Get or create today's daily note. Returns the note ID.
    func getOrCreateDailyNote() async throws -> String {
        let today = formatDate(Date())
        let title = "Daily Note — \(today)"

        // Check if today's note already exists
        if let existing = try await noteRepo.resolveWikiLink(title: title) {
            return existing.id
        }

        // Create today's note with a template
        let template = """
        # \(today)

        ## Tasks
        - [ ]

        ## Notes


        ## Reflections

        """

        let note = try await noteRepo.create(title: title, bodyHTML: template, folderID: nil)
        return note.id
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: date)
    }
}
