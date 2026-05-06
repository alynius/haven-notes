import XCTest

extension XCUIApplication {
    static func launchForTesting() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        return app
    }
}

extension XCUIElement {
    func waitAndTap(timeout: TimeInterval = 5, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(waitForExistence(timeout: timeout), "Element \(identifier) did not appear", file: file, line: line)
        tap()
    }
}

func scrollToElement(_ element: XCUIElement, in scrollView: XCUIElement, maxSwipes: Int = 5) {
    var swipes = 0
    while !element.isHittable && swipes < maxSwipes {
        scrollView.swipeUp()
        swipes += 1
    }
}
