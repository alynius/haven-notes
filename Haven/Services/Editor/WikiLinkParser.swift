import Foundation

final class WikiLinkParser {

    /// Extract all wiki link target titles from content (markdown or HTML).
    /// Looks for [[Title]] patterns in the text.
    func extractLinkTargets(from content: String) -> [String] {
        // Content may be raw markdown or legacy HTML; extract [[links]] directly
        return content.wikiLinkTargets
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
