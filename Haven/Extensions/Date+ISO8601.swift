import Foundation

extension Date {
    var iso8601String: String {
        ISO8601DateFormatter.shared.string(from: self)
    }

    init?(iso8601String: String) {
        guard let date = ISO8601DateFormatter.shared.date(from: iso8601String) else {
            return nil
        }
        self = date
    }
}

extension ISO8601DateFormatter {
    static let shared: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
