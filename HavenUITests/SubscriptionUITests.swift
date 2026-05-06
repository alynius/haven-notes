import XCTest

final class SubscriptionUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication.launchForTesting()
    }

    private func navigateToSubscription() {
        let settingsButton = app.buttons["noteList_button_settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        let subscriptionLink = app.buttons["settings_navLink_subscription"]
        XCTAssertTrue(subscriptionLink.waitForExistence(timeout: 5))
        subscriptionLink.tap()
    }

    // MARK: - Element Visibility

    func test_subscriptionScreenLoads() throws {
        navigateToSubscription()

        let restoreButton = app.buttons["subscription_button_restore"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 10))
    }

    // MARK: - Interactions

    func test_tapRestorePurchases() throws {
        navigateToSubscription()

        let restoreButton = app.buttons["subscription_button_restore"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 10))
        restoreButton.tap()
        // Should not crash — restore may show error or success
    }
}
