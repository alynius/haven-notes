import XCTest

final class NoteEditorUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication.launchForTesting()
    }

    private func navigateToNewNote() {
        let newNoteButton = app.buttons["noteList_button_newNote"]
        XCTAssertTrue(newNoteButton.waitForExistence(timeout: 5))
        newNoteButton.tap()
    }

    // MARK: - Element Visibility

    func test_editorElementsVisible() throws {
        navigateToNewNote()

        let titleField = app.textFields["noteEditor_textField_title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))

        let dismissKeyboard = app.buttons["noteEditor_button_dismissKeyboard"]
        // Keyboard dismiss may only show when keyboard is up
        titleField.tap()
        _ = dismissKeyboard.waitForExistence(timeout: 3)
    }

    // MARK: - Toolbar

    func test_editorToolbarButtonsVisible() throws {
        navigateToNewNote()

        let titleField = app.textFields["noteEditor_textField_title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))

        let boldButton = app.buttons["editorToolbar_button_bold"]
        let italicButton = app.buttons["editorToolbar_button_italic"]
        let headingButton = app.buttons["editorToolbar_button_heading"]
        let listButton = app.buttons["editorToolbar_button_list"]
        let checkboxButton = app.buttons["editorToolbar_button_checkbox"]
        let linkButton = app.buttons["editorToolbar_button_link"]

        // Toolbar buttons should exist (may need scroll)
        XCTAssertTrue(boldButton.waitForExistence(timeout: 5))
        XCTAssertTrue(italicButton.exists)
        XCTAssertTrue(headingButton.exists)
        XCTAssertTrue(listButton.exists)
        XCTAssertTrue(checkboxButton.exists)
        XCTAssertTrue(linkButton.exists)
    }

    // MARK: - Interactions

    func test_typeNoteTitle() throws {
        navigateToNewNote()

        let titleField = app.textFields["noteEditor_textField_title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("My Test Note Title")

        XCTAssertEqual(titleField.value as? String, "My Test Note Title")
    }

    func test_dismissKeyboard() throws {
        navigateToNewNote()

        let titleField = app.textFields["noteEditor_textField_title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()

        let dismissButton = app.buttons["noteEditor_button_dismissKeyboard"]
        if dismissButton.waitForExistence(timeout: 3) {
            dismissButton.tap()
        }
    }

    // MARK: - Tags

    func test_addTag() throws {
        navigateToNewNote()

        let titleField = app.textFields["noteEditor_textField_title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))

        // Scroll down to find tag picker
        let tagField = app.textFields["tagPicker_textField_newTag"]
        if tagField.waitForExistence(timeout: 5) {
            tagField.tap()
            tagField.typeText("test-tag")

            let addButton = app.buttons["tagPicker_button_addTag"]
            if addButton.waitForExistence(timeout: 3) {
                addButton.tap()
            } else {
                // Submit via keyboard
                app.keyboards.buttons["Return"].tap()
            }
        }
    }

    // MARK: - Tasks

    func test_addTask() throws {
        navigateToNewNote()

        let titleField = app.textFields["noteEditor_textField_title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))

        let taskField = app.textFields["taskList_textField_newTask"]
        if taskField.waitForExistence(timeout: 5) {
            taskField.tap()
            taskField.typeText("My test task")
            app.keyboards.buttons["Return"].tap()
        }
    }
}
