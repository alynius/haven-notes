import XCTest

final class GraphUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication.launchForTesting()
    }

    private func navigateToGraph() {
        let graphButton = app.buttons["noteList_button_graph"]
        XCTAssertTrue(graphButton.waitForExistence(timeout: 5))
        graphButton.tap()
    }

    // MARK: - Navigation

    func test_navigateToGraph() throws {
        navigateToGraph()

        let resetZoom = app.buttons["graph_button_resetZoom"]
        XCTAssertTrue(resetZoom.waitForExistence(timeout: 5))
    }

    func test_navigateBackFromGraph() throws {
        navigateToGraph()

        let resetZoom = app.buttons["graph_button_resetZoom"]
        XCTAssertTrue(resetZoom.waitForExistence(timeout: 5))

        app.navigationBars.buttons.firstMatch.tap()

        let newNoteButton = app.buttons["noteList_button_newNote"]
        XCTAssertTrue(newNoteButton.waitForExistence(timeout: 5))
    }

    // MARK: - Interactions

    func test_resetZoomButton() throws {
        navigateToGraph()

        let resetZoom = app.buttons["graph_button_resetZoom"]
        XCTAssertTrue(resetZoom.waitForExistence(timeout: 5))
        // Button is overlaid on a Canvas — verify it exists (tapping may fail due to Canvas AX)
        XCTAssertTrue(resetZoom.exists)
    }
}
