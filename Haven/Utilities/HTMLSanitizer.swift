import Foundation

enum HTMLSanitizer {
    /// Strip all HTML tags and return plain text.
    /// Used to generate body_plaintext for FTS indexing.
    static func stripHTML(_ html: String) -> String {
        guard !html.isEmpty else { return "" }

        var text = html

        // Replace common block elements with newlines
        let blockTags = ["</p>", "</div>", "</li>", "</h1>", "</h2>", "</h3>", "</h4>", "</h5>", "</h6>", "<br>", "<br/>", "<br />"]
        for tag in blockTags {
            text = text.replacingOccurrences(of: tag, with: "\n", options: .caseInsensitive)
        }

        // Remove all remaining HTML tags
        let tagPattern = #"<[^>]+>"#
        if let regex = try? NSRegularExpression(pattern: tagPattern) {
            let range = NSRange(text.startIndex..., in: text)
            text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
        }

        // Decode common HTML entities
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")

        // Collapse multiple newlines and trim
        let newlinePattern = #"\n{3,}"#
        if let regex = try? NSRegularExpression(pattern: newlinePattern) {
            let range = NSRange(text.startIndex..., in: text)
            text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "\n\n")
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
