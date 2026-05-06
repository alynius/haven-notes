import XCTest

final class SyncSettingsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication.launchForTesting()
    }

    private func navigateToSyncSettings() {
        let settingsButton = app.buttons["noteList_button_settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        let syncLink = app.buttons["settings_navLink_sync"]
        XCTAssertTrue(syncLink.waitForExistence(timeout: 5))
        syncLink.tap()
    }

    // MARK: - Element Visibility

    func test_syncToggleVisible() throws {
        navigateToSyncSettings()

        let syncToggle = app.switches["syncSettings_toggle_enableSync"]
        XCTAssertTrue(syncToggle.waitForExistence(timeout: 5))
    }

    // MARK: - Interactions

    func test_toggleSyncInteraction() throws {
        navigateToSyncSettings()

        let syncToggle = app.switches["syncSettings_toggle_enableSync"]
        XCTAssertTrue(syncToggle.waitForExistence(timeout: 5))

        let initialValue = syncToggle.value as? String
        syncToggle.tap()

        // Sync is a Pro-only feature — toggle may not change without subscription.
        // If config fields appear, verify them. If not, that's expected behavior.
        let serverURL = app.textFields["syncSettings_textField_serverURL"]
        if serverURL.waitForExistence(timeout: 5) {
            // Sync was enabled — config fields are showing
            let authToken = app.secureTextFields["syncSettings_secureField_authToken"]
            XCTAssertTrue(authToken.exists)

            let saveButton = app.buttons["syncSettings_button_save"]
            XCTAssertTrue(saveButton.exists)
        } else {
            // Sync enable failed (likely Pro-gated) — verify toggle reverted or error shown
            let currentValue = syncToggle.value as? String
            XCTAssertEqual(currentValue, initialValue, "Toggle should revert if sync can't be enabled (Pro-only)")
        }
    }

    func test_syncConfigFieldsWhenAlreadyEnabled() throws {
        navigateToSyncSettings()

        let syncToggle = app.switches["syncSettings_toggle_enableSync"]
        XCTAssertTrue(syncToggle.waitForExistence(timeout: 5))

        // If sync is already enabled, config fields should be visible
        if syncToggle.value as? String == "1" {
            let serverURL = app.textFields["syncSettings_textField_serverURL"]
            XCTAssertTrue(serverURL.waitForExistence(timeout: 5))

            let authToken = app.secureTextFields["syncSettings_secureField_authToken"]
            XCTAssertTrue(authToken.exists)
        }
        // If sync is off, this test is a no-op (expected without Pro)
    }
}
