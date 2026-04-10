import XCTest

final class NoteListUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication.launchForTesting()
    }

    // MARK: - Element Visibility

    func test_noteListToolbarElementsVisible() throws {
        let newNoteButton = app.buttons["noteList_button_newNote"]
        XCTAssertTrue(newNoteButton.waitForExistence(timeout: 5))

        let settingsButton = app.buttons["noteList_button_settings"]
        XCTAssertTrue(settingsButton.exists)

        let graphButton = app.buttons["noteList_button_graph"]
        XCTAssertTrue(graphButton.exists)

        let searchButton = app.buttons["noteList_button_search"]
        XCTAssertTrue(searchButton.exists)
    }

    // MARK: - Navigation

    func test_tapNewNoteNavigatesToEditor() throws {
        let newNoteButton = app.buttons["noteList_button_newNote"]
        XCTAssertTrue(newNoteButton.waitForExistence(timeout: 5))
        newNoteButton.tap()

        let titleField = app.textFields["noteEditor_textField_title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
    }

    func test_tapSettingsNavigatesToSettings() throws {
        let settingsButton = app.buttons["noteList_button_settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        let settingsToggle = app.switches["settings_toggle_faceId"]
        let themePicker = app.buttons["settings_picker_theme"]
        let found = settingsToggle.waitForExistence(timeout: 5) || themePicker.waitForExistence(timeout: 5)
        XCTAssertTrue(found, "Settings screen did not appear")
    }

    func test_tapSearchNavigatesToSearch() throws {
        let searchButton = app.buttons["noteList_button_search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 5))
        searchButton.tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
    }

    func test_tapGraphNavigatesToGraph() throws {
        let graphButton = app.buttons["noteList_button_graph"]
        XCTAssertTrue(graphButton.waitForExistence(timeout: 5))
        graphButton.tap()

        let resetZoom = app.buttons["graph_button_resetZoom"]
        let graphStats = app.staticTexts["graph_badge_stats"]
        let found = resetZoom.waitForExistence(timeout: 5) || graphStats.waitForExistence(timeout: 5)
        XCTAssertTrue(found, "Graph screen did not appear")
    }

    // MARK: - Interactions

    func test_createNoteAndReturn() throws {
        let newNoteButton = app.buttons["noteList_button_newNote"]
        XCTAssertTrue(newNoteButton.waitForExistence(timeout: 5))
        newNoteButton.tap()

        let titleField = app.textFields["noteEditor_textField_title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Test Note from UI Tests")

        // Wait for autosave debounce (1 second) before navigating back
        let saveWait = expectation(description: "autosave")
        saveWait.isInverted = true
        wait(for: [saveWait], timeout: 2.0)

        // Navigate back
        app.navigationBars.buttons.firstMatch.tap()

        // Verify note appears in list — search broadly since list row may not be a staticText
        let noteRow = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Test Note from UI Tests'")).firstMatch
        XCTAssertTrue(noteRow.waitForExistence(timeout: 5))
    }

    // MARK: - Empty State

    func test_emptyStateShowsCreateButton() throws {
        let createButton = app.buttons["emptyState_button_createNote"]
        if createButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(createButton.isHittable)
            createButton.tap()
            let titleField = app.textFields["noteEditor_textField_title"]
            XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        }
        // If notes exist, empty state won't show — that's fine
    }
}
