import Foundation

extension String {
    /// Extract all [[wiki link]] targets from the string.
    /// Returns an array of link target strings (without the brackets).
    var wikiLinkTargets: [String] {
        let pattern = #"\[\[([^\]]+)\]\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(startIndex..., in: self)
        return regex.matches(in: self, range: range).compactMap { match in
            guard let targetRange = Range(match.range(at: 1), in: self) else { return nil }
            return String(self[targetRange]).trimmingCharacters(in: .whitespaces)
        }
    }

    /// Replace [[wiki link]] markup with a callback that provides the replacement.
    func replacingWikiLinks(_ transform: (String) -> String) -> String {
        let pattern = #"\[\[([^\]]+)\]\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }
        var result = self
        let matches = regex.matches(in: self, range: NSRange(startIndex..., in: self))
        for match in matches.reversed() {
            guard let fullRange = Range(match.range, in: result),
                  let targetRange = Range(match.range(at: 1), in: result) else { continue }
            let target = String(result[targetRange]).trimmingCharacters(in: .whitespaces)
            result.replaceSubrange(fullRange, with: transform(target))
        }
        return result
    }
}
