import XCTest

final class FlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication.launchForTesting()
    }

    // MARK: - End-to-End Flows

    func test_createNoteEditAndReturn() throws {
        // Create a new note
        let newNoteButton = app.buttons["noteList_button_newNote"]
        XCTAssertTrue(newNoteButton.waitForExistence(timeout: 5))
        newNoteButton.tap()

        // Type a title
        let titleField = app.textFields["noteEditor_textField_title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Flow Test Note")

        // Wait for autosave debounce
        let saveWait = expectation(description: "autosave")
        saveWait.isInverted = true
        wait(for: [saveWait], timeout: 2.0)

        // Go back to list
        app.navigationBars.buttons.firstMatch.tap()

        // Verify note shows in list
        let noteText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Flow Test Note'")).firstMatch
        XCTAssertTrue(noteText.waitForExistence(timeout: 5))

        // Tap to re-open
        noteText.tap()

        // Verify title is preserved
        let reopenedTitle = app.textFields["noteEditor_textField_title"]
        XCTAssertTrue(reopenedTitle.waitForExistence(timeout: 5))
        XCTAssertEqual(reopenedTitle.value as? String, "Flow Test Note")
    }

    func test_createNoteSearchAndFind() throws {
        // Create a note with a unique title
        let newNoteButton = app.buttons["noteList_button_newNote"]
        XCTAssertTrue(newNoteButton.waitForExistence(timeout: 5))
        newNoteButton.tap()

        let titleField = app.textFields["noteEditor_textField_title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("UniqueSearchTest42")

        // Go back
        app.navigationBars.buttons.firstMatch.tap()
        _ = newNoteButton.waitForExistence(timeout: 5)

        // Navigate to search
        let searchButton = app.buttons["noteList_button_search"]
        searchButton.tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("UniqueSearchTest42")

        // Should find the note
        let result = app.staticTexts["UniqueSearchTest42"]
        XCTAssertTrue(result.waitForExistence(timeout: 5), "Search should find the note we just created")
    }

    func test_settingsNavigationRoundTrip() throws {
        // Settings → Sync → Back → Encryption → Back → Back to list
        let settingsButton = app.buttons["noteList_button_settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        // Go to Sync
        let syncLink = app.buttons["settings_navLink_sync"]
        XCTAssertTrue(syncLink.waitForExistence(timeout: 5))
        syncLink.tap()

        let syncToggle = app.switches["syncSettings_toggle_enableSync"]
        XCTAssertTrue(syncToggle.waitForExistence(timeout: 5))

        // Back to Settings
        app.navigationBars.buttons.firstMatch.tap()

        // Go to Encryption
        let encryptionLink = app.buttons["settings_navLink_encryption"]
        XCTAssertTrue(encryptionLink.waitForExistence(timeout: 5))
        encryptionLink.tap()

        let passwordField = app.secureTextFields["encryption_secureField_password"]
        let disableButton = app.buttons["encryption_button_disable"]
        let found = passwordField.waitForExistence(timeout: 5) || disableButton.waitForExistence(timeout: 5)
        XCTAssertTrue(found)

        // Back to Settings
        app.navigationBars.buttons.firstMatch.tap()

        // Back to Note List
        app.navigationBars.buttons.firstMatch.tap()

        let newNoteButton = app.buttons["noteList_button_newNote"]
        XCTAssertTrue(newNoteButton.waitForExistence(timeout: 5))
    }
}
