#if os(iOS)
import UIKit
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
#elseif os(macOS)
import AppKit
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
#endif

final class MarkdownHighlighter {

    // MARK: - Theme colors (adapt to trait collection)

    struct Theme {
        let bodyFont: PlatformFont
        let bodyColor: PlatformColor
        let h1Font: PlatformFont
        let h2Font: PlatformFont
        let h3Font: PlatformFont
        let headerColor: PlatformColor
        let boldFont: PlatformFont
        let italicFont: PlatformFont
        let boldItalicFont: PlatformFont
        let syntaxColor: PlatformColor      // dimmed color for **, *, #, etc.
        let linkColor: PlatformColor
        let codeFont: PlatformFont
        let codeBackground: PlatformColor
        let listBulletColor: PlatformColor
        let checkboxColor: PlatformColor
        let strikethroughColor: PlatformColor

        #if os(iOS)
        static func haven(traitCollection: UITraitCollection) -> Theme {
            let isDark = traitCollection.userInterfaceStyle == .dark
            let bodySize: CGFloat = PlatformFont.preferredFont(forTextStyle: .body).pointSize

            return Theme(
                bodyFont: .preferredFont(forTextStyle: .body),
                bodyColor: isDark
                    ? PlatformColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1)
                    : PlatformColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 1),
                h1Font: .systemFont(ofSize: bodySize * 1.6, weight: .bold),
                h2Font: .systemFont(ofSize: bodySize * 1.35, weight: .semibold),
                h3Font: .systemFont(ofSize: bodySize * 1.15, weight: .semibold),
                headerColor: isDark
                    ? PlatformColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1)
                    : PlatformColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 1),
                boldFont: .boldSystemFont(ofSize: bodySize),
                italicFont: .italicSystemFont(ofSize: bodySize),
                boldItalicFont: {
                    let descriptor = PlatformFont.systemFont(ofSize: bodySize).fontDescriptor
                        .withSymbolicTraits([.traitBold, .traitItalic])
                    return PlatformFont(
                        descriptor: descriptor ?? PlatformFont.boldSystemFont(ofSize: bodySize).fontDescriptor,
                        size: bodySize
                    )
                }(),
                syntaxColor: isDark
                    ? PlatformColor(white: 1.0, alpha: 0.25)
                    : PlatformColor(white: 0.0, alpha: 0.2),
                linkColor: PlatformColor(red: 0.42, green: 0.61, blue: 0.56, alpha: 1),
                codeFont: .monospacedSystemFont(ofSize: bodySize * 0.9, weight: .regular),
                codeBackground: isDark
                    ? PlatformColor(white: 1.0, alpha: 0.08)
                    : PlatformColor(white: 0.0, alpha: 0.04),
                listBulletColor: PlatformColor(red: 0.42, green: 0.61, blue: 0.56, alpha: 1),
                checkboxColor: PlatformColor(red: 0.42, green: 0.61, blue: 0.56, alpha: 1),
                strikethroughColor: isDark
                    ? PlatformColor(white: 1.0, alpha: 0.4)
                    : PlatformColor(white: 0.0, alpha: 0.35)
            )
        }
        #elseif os(macOS)
        static func haven(appearance: NSAppearance? = NSAppearance.current) -> Theme {
            let isDark = appearance?.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let bodySize: CGFloat = NSFont.systemFontSize

            return Theme(
                bodyFont: NSFont.systemFont(ofSize: bodySize),
                bodyColor: isDark
                    ? PlatformColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1)
                    : PlatformColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 1),
                h1Font: .systemFont(ofSize: bodySize * 1.6, weight: .bold),
                h2Font: .systemFont(ofSize: bodySize * 1.35, weight: .semibold),
                h3Font: .systemFont(ofSize: bodySize * 1.15, weight: .semibold),
                headerColor: isDark
                    ? PlatformColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1)
                    : PlatformColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 1),
                boldFont: .boldSystemFont(ofSize: bodySize),
                italicFont: {
                    let descriptor = NSFont.systemFont(ofSize: bodySize).fontDescriptor
                        .withSymbolicTraits(.italic)
                    return NSFont(descriptor: descriptor, size: bodySize)
                        ?? NSFont.systemFont(ofSize: bodySize)
                }(),
                boldItalicFont: {
                    let descriptor = NSFont.systemFont(ofSize: bodySize).fontDescriptor
                        .withSymbolicTraits([.bold, .italic])
                    return NSFont(descriptor: descriptor, size: bodySize)
                        ?? NSFont.boldSystemFont(ofSize: bodySize)
                }(),
                syntaxColor: isDark
                    ? PlatformColor(white: 1.0, alpha: 0.25)
                    : PlatformColor(white: 0.0, alpha: 0.2),
                linkColor: PlatformColor(red: 0.42, green: 0.61, blue: 0.56, alpha: 1),
                codeFont: .monospacedSystemFont(ofSize: bodySize * 0.9, weight: .regular),
                codeBackground: isDark
                    ? PlatformColor(white: 1.0, alpha: 0.08)
                    : PlatformColor(white: 0.0, alpha: 0.04),
                listBulletColor: PlatformColor(red: 0.42, green: 0.61, blue: 0.56, alpha: 1),
                checkboxColor: PlatformColor(red: 0.42, green: 0.61, blue: 0.56, alpha: 1),
                strikethroughColor: isDark
                    ? PlatformColor(white: 1.0, alpha: 0.4)
                    : PlatformColor(white: 0.0, alpha: 0.35)
            )
        }
        #endif
    }

    // MARK: - Pre-compiled Regex (static — compiled once at first use)

    private static let headerRegex = try! NSRegularExpression(pattern: #"^(#{1,3})\s+(.+)$"#, options: .anchorsMatchLines)
    private static let boldItalicRegex = try! NSRegularExpression(pattern: #"\*{3}(.+?)\*{3}"#)
    private static let boldRegex = try! NSRegularExpression(pattern: #"\*{2}(.+?)\*{2}"#)
    private static let italicRegex = try! NSRegularExpression(pattern: #"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#)
    private static let inlineCodeRegex = try! NSRegularExpression(pattern: #"`([^`]+)`"#)
    private static let strikethroughRegex = try! NSRegularExpression(pattern: #"~~(.+?)~~"#)
    private static let markdownLinkRegex = try! NSRegularExpression(pattern: #"\[([^\]]+)\]\(([^\)]+)\)"#)
    private static let bareURLRegex = try! NSRegularExpression(pattern: #"(?<!\(|\")(https?://[^\s\)\]]+)"#)
    private static let wikiLinkRegex = try! NSRegularExpression(pattern: #"\[\[([^\]]+)\]\]"#)
    private static let listBulletRegex = try! NSRegularExpression(pattern: #"^(\s*[-*+])\s"#, options: .anchorsMatchLines)
    private static let checkboxRegex = try! NSRegularExpression(pattern: #"^(\s*-\s+\[[ xX]\])"#, options: .anchorsMatchLines)

    private var theme: Theme

    init(theme: Theme) {
        self.theme = theme
    }

    func updateTheme(_ theme: Theme) {
        self.theme = theme
    }

    #if os(iOS)
    func updateTheme(for traitCollection: UITraitCollection) {
        self.theme = Theme.haven(traitCollection: traitCollection)
    }
    #elseif os(macOS)
    func updateTheme(for appearance: NSAppearance? = nil) {
        self.theme = Theme.haven(appearance: appearance ?? NSAppearance.current)
    }
    #endif

    /// Apply markdown highlighting to the full text, returning an NSAttributedString.
    func highlight(_ text: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: text, attributes: [
            .font: theme.bodyFont,
            .foregroundColor: theme.bodyColor
        ])

        let fullRange = NSRange(location: 0, length: attributed.length)

        // Order matters: apply from least to most specific
        applyHeaders(attributed, fullRange: fullRange)
        applyBoldItalic(attributed, fullRange: fullRange)
        applyInlineCode(attributed, fullRange: fullRange)
        applyStrikethrough(attributed, fullRange: fullRange)
        applyLinks(attributed, fullRange: fullRange)
        applyWikiLinks(attributed, fullRange: fullRange)
        applyListBullets(attributed, fullRange: fullRange)
        applyCheckboxes(attributed, fullRange: fullRange)

        return attributed
    }

    // MARK: - Patterns

    private func applyHeaders(_ str: NSMutableAttributedString, fullRange: NSRange) {
        let regex = Self.headerRegex
        for match in regex.matches(in: str.string, range: fullRange) {
            let hashRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let hashCount = hashRange.length

            let font: PlatformFont
            switch hashCount {
            case 1: font = theme.h1Font
            case 2: font = theme.h2Font
            default: font = theme.h3Font
            }

            str.addAttributes([.font: font, .foregroundColor: theme.headerColor], range: contentRange)
            str.addAttributes([.font: font, .foregroundColor: theme.syntaxColor], range: hashRange)
            // Dim the space after #
            let spaceLocation = hashRange.location + hashRange.length
            if spaceLocation < str.length {
                str.addAttribute(.foregroundColor, value: theme.syntaxColor,
                                 range: NSRange(location: spaceLocation, length: 1))
            }
        }
    }

    private func applyBoldItalic(_ str: NSMutableAttributedString, fullRange: NSRange) {
        // ***bold italic***
        applyInlineRegex(Self.boldItalicRegex, to: str, fullRange: fullRange,
                         contentAttrs: [.font: theme.boldItalicFont],
                         syntaxOpenLen: 3, syntaxCloseLen: 3)

        // **bold**
        applyInlineRegex(Self.boldRegex, to: str, fullRange: fullRange,
                         contentAttrs: [.font: theme.boldFont],
                         syntaxOpenLen: 2, syntaxCloseLen: 2)

        // *italic* (but not inside **)
        applyInlineRegex(Self.italicRegex, to: str, fullRange: fullRange,
                         contentAttrs: [.font: theme.italicFont],
                         syntaxOpenLen: 1, syntaxCloseLen: 1)
    }

    private func applyInlineCode(_ str: NSMutableAttributedString, fullRange: NSRange) {
        let regex = Self.inlineCodeRegex
        for match in regex.matches(in: str.string, range: fullRange) {
            let fullMatch = match.range
            let contentRange = match.range(at: 1)

            str.addAttributes([
                .font: theme.codeFont,
                .backgroundColor: theme.codeBackground
            ], range: contentRange)

            let openTick = NSRange(location: fullMatch.location, length: 1)
            let closeTick = NSRange(location: fullMatch.location + fullMatch.length - 1, length: 1)
            str.addAttribute(.foregroundColor, value: theme.syntaxColor, range: openTick)
            str.addAttribute(.foregroundColor, value: theme.syntaxColor, range: closeTick)
        }
    }

    private func applyStrikethrough(_ str: NSMutableAttributedString, fullRange: NSRange) {
        let regex = Self.strikethroughRegex
        for match in regex.matches(in: str.string, range: fullRange) {
            let contentRange = match.range(at: 1)
            str.addAttributes([
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: theme.strikethroughColor
            ], range: contentRange)

            let openSyntax = NSRange(location: match.range.location, length: 2)
            let closeSyntax = NSRange(location: match.range.location + match.range.length - 2, length: 2)
            str.addAttribute(.foregroundColor, value: theme.syntaxColor, range: openSyntax)
            str.addAttribute(.foregroundColor, value: theme.syntaxColor, range: closeSyntax)
        }
    }

    private func applyLinks(_ str: NSMutableAttributedString, fullRange: NSRange) {
        // Markdown links: [text](url)
        for match in Self.markdownLinkRegex.matches(in: str.string, range: fullRange) {
            let textRange = match.range(at: 1)
            let urlRange = match.range(at: 2)
            let urlString = (str.string as NSString).substring(with: urlRange)

            str.addAttributes([
                .foregroundColor: theme.linkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: textRange)

            // Make the link text tappable
            if let url = URL(string: urlString) {
                str.addAttribute(.link, value: url, range: textRange)
            }

            // Dim all syntax chars around the link text
            let fullMatch = match.range
            let openBracket = NSRange(location: fullMatch.location, length: 1)
            str.addAttribute(.foregroundColor, value: theme.syntaxColor, range: openBracket)

            let syntaxAfterText = NSRange(
                location: textRange.location + textRange.length,
                length: fullMatch.length - textRange.length - 1
            )
            str.addAttribute(.foregroundColor, value: theme.syntaxColor, range: syntaxAfterText)
        }

        // Bare URLs (https://... or http://...)
        for match in Self.bareURLRegex.matches(in: str.string, range: fullRange) {
            let urlRange = match.range(at: 1)
            let urlString = (str.string as NSString).substring(with: urlRange)

            // Skip if this URL is already inside a markdown link ](url)
            if urlRange.location > 0 {
                let charBefore = (str.string as NSString).substring(with: NSRange(location: urlRange.location - 1, length: 1))
                if charBefore == "(" { continue }
            }

            if let url = URL(string: urlString) {
                str.addAttributes([
                    .foregroundColor: theme.linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .link: url
                ], range: urlRange)
            }
        }
    }

    private func applyWikiLinks(_ str: NSMutableAttributedString, fullRange: NSRange) {
        for match in Self.wikiLinkRegex.matches(in: str.string, range: fullRange) {
            let contentRange = match.range(at: 1)
            str.addAttribute(.foregroundColor, value: theme.linkColor, range: contentRange)

            let openBrackets = NSRange(location: match.range.location, length: 2)
            let closeBrackets = NSRange(location: match.range.location + match.range.length - 2, length: 2)
            str.addAttribute(.foregroundColor, value: theme.syntaxColor, range: openBrackets)
            str.addAttribute(.foregroundColor, value: theme.syntaxColor, range: closeBrackets)
        }
    }

    private func applyListBullets(_ str: NSMutableAttributedString, fullRange: NSRange) {
        for match in Self.listBulletRegex.matches(in: str.string, range: fullRange) {
            let bulletRange = match.range(at: 1)
            str.addAttribute(.foregroundColor, value: theme.listBulletColor, range: bulletRange)
        }
    }

    private func applyCheckboxes(_ str: NSMutableAttributedString, fullRange: NSRange) {
        for match in Self.checkboxRegex.matches(in: str.string, range: fullRange) {
            let checkboxRange = match.range(at: 1)
            str.addAttribute(.foregroundColor, value: theme.checkboxColor, range: checkboxRange)
        }
    }

    // MARK: - Helper

    private func applyInlineRegex(_ regex: NSRegularExpression, to str: NSMutableAttributedString,
                                   fullRange: NSRange, contentAttrs: [NSAttributedString.Key: Any],
                                   syntaxOpenLen: Int, syntaxCloseLen: Int) {
        for match in regex.matches(in: str.string, range: fullRange) {
            let contentRange = match.range(at: 1)
            str.addAttributes(contentAttrs, range: contentRange)

            // Dim opening syntax
            let openRange = NSRange(location: match.range.location, length: syntaxOpenLen)
            if openRange.location + openRange.length <= str.length {
                str.addAttribute(.foregroundColor, value: theme.syntaxColor, range: openRange)
            }

            // Dim closing syntax
            let closeStart = match.range.location + match.range.length - syntaxCloseLen
            let closeRange = NSRange(location: closeStart, length: syntaxCloseLen)
            if closeRange.location >= 0 && closeRange.location + closeRange.length <= str.length {
                str.addAttribute(.foregroundColor, value: theme.syntaxColor, range: closeRange)
            }
        }
    }
}
