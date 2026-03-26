import XCTest
@testable import Haven

final class DateISO8601Tests: XCTestCase {

    func testDateToISO8601String() {
        let date = Date(timeIntervalSince1970: 0)
        let str = date.iso8601String
        XCTAssertTrue(str.hasPrefix("1970-01-01T00:00:00"))
    }

    func testISO8601StringToDate() {
        let str = "2026-03-26T10:30:00.000Z"
        let date = Date(iso8601String: str)
        XCTAssertNotNil(date)
    }

    func testRoundTrip() {
        let original = Date()
        let str = original.iso8601String
        let decoded = Date(iso8601String: str)
        XCTAssertNotNil(decoded)
        // Allow 1ms tolerance due to fractional second formatting
        if let decoded = decoded {
            XCTAssertEqual(original.timeIntervalSince1970, decoded.timeIntervalSince1970, accuracy: 0.001)
        }
    }

    func testInvalidStringReturnsNil() {
        XCTAssertNil(Date(iso8601String: "not a date"))
        XCTAssertNil(Date(iso8601String: ""))
        XCTAssertNil(Date(iso8601String: "2026-13-45"))
    }
}
