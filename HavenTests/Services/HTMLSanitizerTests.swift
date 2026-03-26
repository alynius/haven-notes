import XCTest
@testable import Haven

final class HTMLSanitizerTests: XCTestCase {

    func testStripsParagraphTags() {
        let html = "<p>Hello world</p>"
        let result = HTMLSanitizer.stripHTML(html)
        XCTAssertEqual(result, "Hello world")
    }

    func testStripsNestedTags() {
        let html = "<p>Hello <strong>bold</strong> and <em>italic</em></p>"
        let result = HTMLSanitizer.stripHTML(html)
        XCTAssertEqual(result, "Hello bold and italic")
    }

    func testConvertsBlockTagsToNewlines() {
        let html = "<p>First</p><p>Second</p>"
        let result = HTMLSanitizer.stripHTML(html)
        XCTAssertTrue(result.contains("First"))
        XCTAssertTrue(result.contains("Second"))
    }

    func testHandlesBrTags() {
        let html = "Line one<br>Line two<br/>Line three"
        let result = HTMLSanitizer.stripHTML(html)
        XCTAssertTrue(result.contains("Line one"))
        XCTAssertTrue(result.contains("Line two"))
        XCTAssertTrue(result.contains("Line three"))
    }

    func testDecodesHTMLEntities() {
        let html = "Tom &amp; Jerry &lt;3 &quot;cats&quot;"
        let result = HTMLSanitizer.stripHTML(html)
        XCTAssertTrue(result.contains("Tom & Jerry"))
        XCTAssertTrue(result.contains("<3"))
        XCTAssertTrue(result.contains("\"cats\""))
    }

    func testHandlesEmptyString() {
        XCTAssertEqual(HTMLSanitizer.stripHTML(""), "")
    }

    func testHandlesPlainText() {
        let text = "No HTML here"
        XCTAssertEqual(HTMLSanitizer.stripHTML(text), "No HTML here")
    }

    func testStripsHeadingTags() {
        let html = "<h1>Title</h1><h2>Subtitle</h2><p>Body</p>"
        let result = HTMLSanitizer.stripHTML(html)
        XCTAssertTrue(result.contains("Title"))
        XCTAssertTrue(result.contains("Subtitle"))
        XCTAssertTrue(result.contains("Body"))
    }

    func testCollapsesMultipleNewlines() {
        let html = "<p>A</p><p></p><p></p><p></p><p>B</p>"
        let result = HTMLSanitizer.stripHTML(html)
        // Should not have more than 2 consecutive newlines
        XCTAssertFalse(result.contains("\n\n\n"))
    }

    func testStripsListItems() {
        let html = "<ul><li>Item 1</li><li>Item 2</li></ul>"
        let result = HTMLSanitizer.stripHTML(html)
        XCTAssertTrue(result.contains("Item 1"))
        XCTAssertTrue(result.contains("Item 2"))
    }
}
