import XCTest
@testable import Haven

final class ConflictResolverTests: XCTestCase {
    let resolver = ConflictResolver()

    // MARK: - Note conflict resolution

    func testRemoteWinsWhenNewer() {
        let local = Note(id: "1", title: "Local", updatedAt: Date(timeIntervalSince1970: 1000))
        let remote = Note(id: "1", title: "Remote", updatedAt: Date(timeIntervalSince1970: 2000))

        let winner = resolver.resolve(local: local, remote: remote)
        XCTAssertEqual(winner.title, "Remote")
    }

    func testLocalWinsWhenNewer() {
        let local = Note(id: "1", title: "Local", updatedAt: Date(timeIntervalSince1970: 2000))
        let remote = Note(id: "1", title: "Remote", updatedAt: Date(timeIntervalSince1970: 1000))

        let winner = resolver.resolve(local: local, remote: remote)
        XCTAssertEqual(winner.title, "Local")
    }

    func testLocalWinsOnTie() {
        let timestamp = Date(timeIntervalSince1970: 1000)
        let local = Note(id: "1", title: "Local", updatedAt: timestamp)
        let remote = Note(id: "1", title: "Remote", updatedAt: timestamp)

        let winner = resolver.resolve(local: local, remote: remote)
        XCTAssertEqual(winner.title, "Local")
    }

    // MARK: - Task conflict resolution

    func testTaskRemoteWinsWhenNewer() {
        let local = NoteTask(id: "1", noteID: "n1", text: "Local", updatedAt: Date(timeIntervalSince1970: 1000))
        let remote = NoteTask(id: "1", noteID: "n1", text: "Remote", updatedAt: Date(timeIntervalSince1970: 2000))

        let winner = resolver.resolve(local: local, remote: remote)
        XCTAssertEqual(winner.text, "Remote")
    }

    func testTaskLocalWinsWhenNewer() {
        let local = NoteTask(id: "1", noteID: "n1", text: "Local", updatedAt: Date(timeIntervalSince1970: 2000))
        let remote = NoteTask(id: "1", noteID: "n1", text: "Remote", updatedAt: Date(timeIntervalSince1970: 1000))

        let winner = resolver.resolve(local: local, remote: remote)
        XCTAssertEqual(winner.text, "Local")
    }

    // MARK: - Conflict detection

    func testNoConflictWhenNeverSynced() {
        let result = resolver.hasConflict(
            localUpdatedAt: Date(timeIntervalSince1970: 2000),
            remoteUpdatedAt: Date(timeIntervalSince1970: 2000),
            lastSyncAt: nil
        )
        XCTAssertFalse(result)
    }

    func testConflictWhenBothModifiedAfterSync() {
        let lastSync = Date(timeIntervalSince1970: 1000)
        let result = resolver.hasConflict(
            localUpdatedAt: Date(timeIntervalSince1970: 2000),
            remoteUpdatedAt: Date(timeIntervalSince1970: 1500),
            lastSyncAt: lastSync
        )
        XCTAssertTrue(result)
    }

    func testNoConflictWhenOnlyLocalModified() {
        let lastSync = Date(timeIntervalSince1970: 1000)
        let result = resolver.hasConflict(
            localUpdatedAt: Date(timeIntervalSince1970: 2000),
            remoteUpdatedAt: Date(timeIntervalSince1970: 500),
            lastSyncAt: lastSync
        )
        XCTAssertFalse(result)
    }

    func testNoConflictWhenOnlyRemoteModified() {
        let lastSync = Date(timeIntervalSince1970: 1000)
        let result = resolver.hasConflict(
            localUpdatedAt: Date(timeIntervalSince1970: 500),
            remoteUpdatedAt: Date(timeIntervalSince1970: 2000),
            lastSyncAt: lastSync
        )
        XCTAssertFalse(result)
    }
}
