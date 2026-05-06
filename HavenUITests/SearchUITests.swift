import XCTest

final class SearchUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication.launchForTesting()
    }

    private func navigateToSearch() {
        let searchButton = app.buttons["noteList_button_search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 5))
        searchButton.tap()
    }

    // MARK: - Navigation

    func test_navigateToSearch() throws {
        navigateToSearch()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
    }

    func test_navigateBackFromSearch() throws {
        navigateToSearch()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        // Go back
        app.navigationBars.buttons.firstMatch.tap()

        let newNoteButton = app.buttons["noteList_button_newNote"]
        XCTAssertTrue(newNoteButton.waitForExistence(timeout: 5))
    }

    // MARK: - Interactions

    func test_typeInSearchField() throws {
        navigateToSearch()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("test query")
    }

    func test_clearSearch() throws {
        navigateToSearch()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("test")

        // Look for clear button
        let clearButton = app.buttons["search_button_clear"]
        if clearButton.waitForExistence(timeout: 3) {
            clearButton.tap()
        }
    }
}
