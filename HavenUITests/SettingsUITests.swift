import XCTest

final class SettingsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication.launchForTesting()
    }

    private func navigateToSettings() {
        let settingsButton = app.buttons["noteList_button_settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
    }

    // MARK: - Navigation

    func test_navigateToSettings() throws {
        navigateToSettings()

        // Settings should show theme picker or biometric toggle
        let themePicker = app.buttons["settings_picker_theme"]
        let biometricToggle = app.switches["settings_toggle_faceId"]
        let found = themePicker.waitForExistence(timeout: 5) || biometricToggle.waitForExistence(timeout: 5)
        XCTAssertTrue(found, "Settings screen did not load")
    }

    func test_navigateBackFromSettings() throws {
        navigateToSettings()

        // Wait for settings to load
        _ = app.buttons["settings_picker_theme"].waitForExistence(timeout: 5)

        app.navigationBars.buttons.firstMatch.tap()

        let newNoteButton = app.buttons["noteList_button_newNote"]
        XCTAssertTrue(newNoteButton.waitForExistence(timeout: 5))
    }

    // MARK: - Element Visibility

    func test_settingsElementsVisible() throws {
        navigateToSettings()

        let importButton = app.buttons["settings_button_importNotion"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 5))

        let syncLink = app.buttons["settings_navLink_sync"]
        XCTAssertTrue(syncLink.waitForExistence(timeout: 5))

        let encryptionLink = app.buttons["settings_navLink_encryption"]
        XCTAssertTrue(encryptionLink.waitForExistence(timeout: 5))

        let subscriptionLink = app.buttons["settings_navLink_subscription"]
        XCTAssertTrue(subscriptionLink.waitForExistence(timeout: 5))
    }

    // MARK: - Interactions

    func test_tapThemePicker() throws {
        navigateToSettings()

        let themePicker = app.buttons["settings_picker_theme"]
        if themePicker.waitForExistence(timeout: 5) {
            themePicker.tap()
            // Theme options should appear
        }
    }

    func test_navigateToSyncSettings() throws {
        navigateToSettings()

        let syncLink = app.buttons["settings_navLink_sync"]
        XCTAssertTrue(syncLink.waitForExistence(timeout: 5))
        syncLink.tap()

        let syncToggle = app.switches["syncSettings_toggle_enableSync"]
        XCTAssertTrue(syncToggle.waitForExistence(timeout: 5))
    }

    func test_navigateToEncryption() throws {
        navigateToSettings()

        let encryptionLink = app.buttons["settings_navLink_encryption"]
        XCTAssertTrue(encryptionLink.waitForExistence(timeout: 5))
        encryptionLink.tap()

        let passwordField = app.secureTextFields["encryption_secureField_password"]
        let disableButton = app.buttons["encryption_button_disable"]
        let found = passwordField.waitForExistence(timeout: 5) || disableButton.waitForExistence(timeout: 5)
        XCTAssertTrue(found, "Encryption screen did not load")
    }

    func test_navigateToSubscription() throws {
        navigateToSettings()

        let subscriptionLink = app.buttons["settings_navLink_subscription"]
        XCTAssertTrue(subscriptionLink.waitForExistence(timeout: 5))
        subscriptionLink.tap()

        let restoreButton = app.buttons["subscription_button_restore"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 5))
    }

    func test_tapImportNotion() throws {
        navigateToSettings()

        let importButton = app.buttons["settings_button_importNotion"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 5))
        importButton.tap()

        let selectButton = app.buttons["notionImport_button_select"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 5))
    }
}
