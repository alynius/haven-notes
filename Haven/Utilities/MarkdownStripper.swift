import Foundation

enum MarkdownStripper {
    /// Strip markdown syntax to produce plain text for FTS indexing.
    static func stripMarkdown(_ text: String) -> String {
        var result = text

        // Remove headers (multiline: ^ must match line start)
        result = regexReplace(result, pattern: #"^#{1,6}\s+"#, with: "", multiline: true)
        // Remove bold/italic markers
        result = regexReplace(result, pattern: #"\*{1,3}"#, with: "", multiline: false)
        // Remove strikethrough
        result = result.replacingOccurrences(of: "~~", with: "")
        // Remove inline code backticks
        result = result.replacingOccurrences(of: "`", with: "")
        // Remove link syntax [text](url) -> text
        result = regexReplace(result, pattern: #"\[([^\]]+)\]\([^\)]+\)"#, with: "$1", multiline: false)
        // Remove wiki link brackets
        result = result.replacingOccurrences(of: "[[", with: "")
        result = result.replacingOccurrences(of: "]]", with: "")
        // Remove checkbox syntax
        result = regexReplace(result, pattern: #"- \[[ xX]\]\s?"#, with: "", multiline: false)
        // Remove list bullets (multiline: ^ must match line start)
        result = regexReplace(result, pattern: #"^\s*[-*+]\s+"#, with: "", multiline: true)

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Helper that uses NSRegularExpression with anchorsMatchLines option.
    private static func regexReplace(_ text: String, pattern: String, with template: String, multiline: Bool) -> String {
        var options: NSRegularExpression.Options = []
        if multiline {
            options.insert(.anchorsMatchLines)
        }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: template)
    }
}
