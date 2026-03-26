import Foundation

final class WikiLinkParser {

    /// Extract all wiki link target titles from HTML content.
    /// Looks for [[Title]] patterns in the text.
    func extractLinkTargets(from html: String) -> [String] {
        // Strip HTML first to get plain text, then extract [[links]]
        let plaintext = HTMLSanitizer.stripHTML(html)
        return plaintext.wikiLinkTargets
    }

    /// Check if a string contains any wiki links.
    func containsWikiLinks(_ text: String) -> Bool {
        !text.wikiLinkTargets.isEmpty
    }

    /// Get autocomplete suggestions based on partial input after [[
    /// Returns the partial text the user is currently typing inside [[...
    func extractPartialWikiLink(from text: String, cursorPosition: Int) -> String? {
        // Look backwards from cursor for [[ without a closing ]]
        guard cursorPosition <= text.count else { return nil }
        let prefix = String(text.prefix(cursorPosition))

        // Find the last [[ that doesn't have a matching ]]
        guard let openRange = prefix.range(of: "[[", options: .backwards) else { return nil }
        let afterOpen = prefix[openRange.upperBound...]

        // If there's a ]] after the [[, it's already closed
        if afterOpen.contains("]]") { return nil }

        return String(afterOpen).trimmingCharacters(in: .whitespaces)
    }
}
