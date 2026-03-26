import XCTest
@testable import Haven

final class NoteModelTests: XCTestCase {

    func testDefaultInitialization() {
        let note = Note()
        XCTAssertFalse(note.id.isEmpty)
        XCTAssertEqual(note.title, "")
        XCTAssertEqual(note.bodyHTML, "")
        XCTAssertEqual(note.bodyPlaintext, "")
        XCTAssertFalse(note.isPinned)
        XCTAssertFalse(note.isDeleted)
    }

    func testCustomInitialization() {
        let note = Note(
            id: "custom-id",
            title: "Test Note",
            bodyHTML: "<p>Hello</p>",
            bodyPlaintext: "Hello",
            isPinned: true
        )
        XCTAssertEqual(note.id, "custom-id")
        XCTAssertEqual(note.title, "Test Note")
        XCTAssertTrue(note.isPinned)
    }

    func testEquality() {
        let a = Note(id: "1", title: "Same")
        let b = Note(id: "1", title: "Same")
        // They have different dates so won't be equal unless dates match
        XCTAssertNotEqual(a, b) // Different createdAt/updatedAt

        let timestamp = Date()
        let c = Note(id: "1", title: "Same", createdAt: timestamp, updatedAt: timestamp)
        let d = Note(id: "1", title: "Same", createdAt: timestamp, updatedAt: timestamp)
        XCTAssertEqual(c, d)
    }

    func testCodable() throws {
        let note = Note(id: "test", title: "Codable Test", bodyHTML: "<p>Hi</p>")
        let data = try JSONEncoder().encode(note)
        let decoded = try JSONDecoder().decode(Note.self, from: data)
        XCTAssertEqual(decoded.id, "test")
        XCTAssertEqual(decoded.title, "Codable Test")
        XCTAssertEqual(decoded.bodyHTML, "<p>Hi</p>")
    }

    func testTaskDefaultInitialization() {
        let task = NoteTask(noteID: "note-1")
        XCTAssertFalse(task.id.isEmpty)
        XCTAssertEqual(task.noteID, "note-1")
        XCTAssertEqual(task.text, "")
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.position, 0)
    }

    func testTaskCodable() throws {
        let task = NoteTask(id: "t1", noteID: "n1", text: "Do thing", isCompleted: true, position: 3)
        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(NoteTask.self, from: data)
        XCTAssertEqual(decoded.id, "t1")
        XCTAssertEqual(decoded.text, "Do thing")
        XCTAssertTrue(decoded.isCompleted)
        XCTAssertEqual(decoded.position, 3)
    }

    func testWikiLinkModel() {
        let link = WikiLink(sourceNoteID: "a", targetNoteID: "b", linkText: "My Link")
        XCTAssertEqual(link.sourceNoteID, "a")
        XCTAssertEqual(link.targetNoteID, "b")
        XCTAssertEqual(link.linkText, "My Link")
    }

    func testSyncLogEntry() {
        let entry = SyncLogEntry(id: 1, entityType: "note", entityID: "n1", operation: "insert", timestamp: Date())
        XCTAssertEqual(entry.id, 1)
        XCTAssertNil(entry.syncedAt)
    }
}
