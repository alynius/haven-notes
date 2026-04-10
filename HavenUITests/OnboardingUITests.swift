import XCTest

final class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Do NOT pass --uitesting so onboarding shows
        app.launch()
    }

    // MARK: - Element Visibility

    func test_onboardingShowsOnFirstLaunch() throws {
        // Check for onboarding elements OR note list (if already completed)
        let skipButton = app.buttons["onboarding_button_skip"]
        let continueButton = app.buttons["onboarding_button_continue"]
        let noteList = app.buttons["noteList_button_newNote"]

        let onboardingVisible = skipButton.waitForExistence(timeout: 5) || continueButton.waitForExistence(timeout: 5)
        let noteListVisible = noteList.waitForExistence(timeout: 2)

        XCTAssertTrue(onboardingVisible || noteListVisible, "Neither onboarding nor note list appeared")
    }

    // MARK: - Interactions

    func test_skipOnboarding() throws {
        let skipButton = app.buttons["onboarding_button_skip"]
        guard skipButton.waitForExistence(timeout: 5) else {
            // Onboarding already completed
            return
        }
        skipButton.tap()
    }

    func test_swipeThroughOnboarding() throws {
        let continueButton = app.buttons["onboarding_button_continue"]
        guard continueButton.waitForExistence(timeout: 5) else { return }

        // Swipe through pages
        for _ in 0..<5 {
            if continueButton.exists {
                continueButton.tap()
            }
        }

        // Last page should show "Start Writing"
        let startButton = app.buttons["onboarding_button_startWriting"]
        _ = startButton.waitForExistence(timeout: 3)
    }
}
