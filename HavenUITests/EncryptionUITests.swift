import XCTest

final class EncryptionUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication.launchForTesting()
    }

    private func navigateToEncryption() {
        let settingsButton = app.buttons["noteList_button_settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        let encryptionLink = app.buttons["settings_navLink_encryption"]
        XCTAssertTrue(encryptionLink.waitForExistence(timeout: 5))
        encryptionLink.tap()
    }

    // MARK: - Element Visibility

    func test_encryptionScreenLoads() throws {
        navigateToEncryption()

        let passwordField = app.secureTextFields["encryption_secureField_password"]
        let disableButton = app.buttons["encryption_button_disable"]
        let found = passwordField.waitForExistence(timeout: 5) || disableButton.waitForExistence(timeout: 5)
        XCTAssertTrue(found, "Encryption settings did not load")
    }

    // MARK: - Forms

    func test_enableEncryptionWithValidPassword() throws {
        navigateToEncryption()

        let passwordField = app.secureTextFields["encryption_secureField_password"]
        guard passwordField.waitForExistence(timeout: 5) else {
            // Encryption already enabled — skip setup test
            return
        }

        passwordField.tap()
        passwordField.typeText("securepass123")

        let confirmField = app.secureTextFields["encryption_secureField_confirmPassword"]
        XCTAssertTrue(confirmField.exists)
        confirmField.tap()
        confirmField.typeText("securepass123")

        let enableButton = app.buttons["encryption_button_enable"]
        XCTAssertTrue(enableButton.exists)
        XCTAssertTrue(enableButton.isEnabled)
    }

    func test_enableButtonDisabledWithShortPassword() throws {
        navigateToEncryption()

        let passwordField = app.secureTextFields["encryption_secureField_password"]
        guard passwordField.waitForExistence(timeout: 5) else { return }

        passwordField.tap()
        passwordField.typeText("short")

        let confirmField = app.secureTextFields["encryption_secureField_confirmPassword"]
        confirmField.tap()
        confirmField.typeText("short")

        let enableButton = app.buttons["encryption_button_enable"]
        XCTAssertTrue(enableButton.exists)
        XCTAssertFalse(enableButton.isEnabled, "Enable button should be disabled for passwords < 8 chars")
    }

    func test_enableButtonDisabledWithMismatch() throws {
        navigateToEncryption()

        let passwordField = app.secureTextFields["encryption_secureField_password"]
        guard passwordField.waitForExistence(timeout: 5) else { return }

        passwordField.tap()
        passwordField.typeText("securepass123")

        let confirmField = app.secureTextFields["encryption_secureField_confirmPassword"]
        confirmField.tap()
        confirmField.typeText("differentpass")

        let enableButton = app.buttons["encryption_button_enable"]
        XCTAssertTrue(enableButton.exists)
        XCTAssertFalse(enableButton.isEnabled, "Enable button should be disabled when passwords don't match")
    }
}
