#if os(macOS)
import AppKit
import SwiftUI

/// NSTextViewDelegate coordinator for the macOS markdown editor.
/// Mirrors the role of RichTextEditor.Coordinator on iOS.
final class MacTextViewCoordinator: NSObject, NSTextViewDelegate, ObservableObject {

    var htmlContent: Binding<String>
    var onTextChanged: ((String) -> Void)?
    var onLinkTapped: ((String) -> Void)?

    weak var textView: NSTextView?

    private let highlighter: MarkdownHighlighter
    var isEditing: Bool = false
    private var highlightWorkItem: DispatchWorkItem?
    private let highlightDebounce: TimeInterval = 0.1
    private var lastAppearanceName: NSAppearance.Name?

    @Published var activeFormats: Set<MarkdownFormat> = []

    init(htmlContent: Binding<String>,
         onTextChanged: ((String) -> Void)?,
         onLinkTapped: ((String) -> Void)?) {
        self.htmlContent = htmlContent
        self.onTextChanged = onTextChanged
        self.onLinkTapped = onLinkTapped
        let theme = MarkdownHighlighter.Theme.haven(appearance: NSApplication.shared.effectiveAppearance)
        self.highlighter = MarkdownHighlighter(theme: theme)
    }

    // MARK: - NSTextViewDelegate

    func textDidBeginEditing(_ notification: Notification) {
        isEditing = true
    }

    func textDidEndEditing(_ notification: Notification) {
        isEditing = false
        guard let tv = textView else { return }
        let text = tv.string
        applyHighlighting(to: tv, text: text)
    }

    func textDidChange(_ notification: Notification) {
        guard let tv = textView else { return }
        let text = tv.string

        // Update the binding immediately
        htmlContent.wrappedValue = text
        onTextChanged?(text)

        // Detect active formats at cursor
        detectActiveFormats(in: text)

        // Debounce highlighting
        highlightWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, let tv = self.textView else { return }
            self.applyHighlighting(to: tv, text: tv.string)
        }
        highlightWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + highlightDebounce, execute: workItem)
    }

    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        if let url = link as? URL {
            // Check if the link is a wiki link
            let wikiLinkRegex = try? NSRegularExpression(pattern: #"\[\[([^\]]+)\]\]"#)
            let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
            if let matches = wikiLinkRegex?.matches(in: textView.string, range: fullRange) {
                for match in matches {
                    let contentRange = match.range(at: 1)
                    if contentRange.location <= charIndex && charIndex <= contentRange.location + contentRange.length {
                        let title = (textView.string as NSString).substring(with: contentRange)
                        onLinkTapped?(title)
                        return true
                    }
                }
            }
            NSWorkspace.shared.open(url)
        }
        return true
    }

    // MARK: - Highlighting

    func applyHighlighting(to textView: NSTextView, text: String) {
        guard let textStorage = textView.textStorage else { return }

        let appearanceName = textView.effectiveAppearance.name
        if appearanceName != lastAppearanceName {
            highlighter.updateTheme(for: textView.effectiveAppearance)
            lastAppearanceName = appearanceName
        }

        let highlighted = highlighter.highlight(text)

        if highlighted.string == textStorage.string {
            // Incremental: only attributes change. Layout, scroll, and selection are preserved.
            let fullRange = NSRange(location: 0, length: textStorage.length)
            textStorage.beginEditing()
            textStorage.setAttributes([:], range: fullRange)
            highlighted.enumerateAttributes(in: NSRange(location: 0, length: highlighted.length)) { attrs, range, _ in
                textStorage.setAttributes(attrs, range: range)
            }
            textStorage.endEditing()
        } else {
            // Full replacement path — initial load or external text sync.
            let selectedRange = textView.selectedRange()
            textStorage.beginEditing()
            textStorage.setAttributedString(highlighted)
            textStorage.endEditing()
            let maxLocation = (textView.string as NSString).length
            let safeLocation = min(selectedRange.location, maxLocation)
            let safeLength = min(selectedRange.length, maxLocation - safeLocation)
            textView.setSelectedRange(NSRange(location: safeLocation, length: safeLength))
        }
    }

    // MARK: - Toolbar Actions

    func toggleBold() {
        wrapOrInsert(prefix: "**", suffix: "**", placeholder: "bold")
    }

    func toggleItalic() {
        wrapOrInsert(prefix: "*", suffix: "*", placeholder: "italic")
    }

    func toggleHeading() {
        guard let tv = textView else { return }
        var text = tv.string
        let selectedRange = tv.selectedRange()
        let nsText = text as NSString
        let lineRange = nsText.lineRange(for: selectedRange)
        let line = nsText.substring(with: lineRange)

        var currentLevel = 0
        for ch in line {
            if ch == "#" { currentLevel += 1 } else { break }
        }

        let stripped: String
        if currentLevel > 0 {
            let drop = line.drop(while: { $0 == "#" })
            stripped = String(drop.hasPrefix(" ") ? drop.dropFirst() : drop)
        } else {
            stripped = line
        }

        let nextLevel = currentLevel >= 3 ? 0 : currentLevel + 1
        let newPrefix = nextLevel > 0 ? String(repeating: "#", count: nextLevel) + " " : ""
        let newLine = newPrefix + stripped

        text = nsText.replacingCharacters(in: lineRange, with: newLine)
        commitText(text, to: tv)

        let cursorOffset = selectedRange.location - lineRange.location
        let delta = newPrefix.count - (currentLevel > 0 ? currentLevel + 1 : 0)
        let newCursor = lineRange.location + min(cursorOffset + delta, newLine.count)
        tv.setSelectedRange(NSRange(location: max(lineRange.location, newCursor), length: 0))
    }

    func toggleList() {
        toggleLinePrefix("- ")
    }

    func toggleTask() {
        toggleLinePrefix("- [ ] ")
    }

    func toggleCode() {
        wrapOrInsert(prefix: "`", suffix: "`", placeholder: "code")
    }

    func insertWikiLink() {
        guard let tv = textView else { return }
        let selectedRange = tv.selectedRange()
        var text = tv.string
        let nsText = text as NSString

        if selectedRange.length > 0 {
            let selectedText = nsText.substring(with: selectedRange)
            let replacement = "[[\(selectedText)]]"
            text = nsText.replacingCharacters(in: selectedRange, with: replacement)
            commitText(text, to: tv)
            tv.setSelectedRange(NSRange(location: selectedRange.location + 2, length: selectedText.count))
        } else {
            let replacement = "[[link]]"
            text = nsText.replacingCharacters(in: selectedRange, with: replacement)
            commitText(text, to: tv)
            tv.setSelectedRange(NSRange(location: selectedRange.location + 2, length: 4))
        }
    }

    // MARK: - Private Helpers

    private func wrapOrInsert(prefix: String, suffix: String, placeholder: String) {
        guard let tv = textView else { return }
        let selectedRange = tv.selectedRange()
        var text = tv.string
        let nsText = text as NSString

        if selectedRange.length > 0 {
            let selectedText = nsText.substring(with: selectedRange)
            let replacement = "\(prefix)\(selectedText)\(suffix)"
            text = nsText.replacingCharacters(in: selectedRange, with: replacement)
            commitText(text, to: tv)
            tv.setSelectedRange(NSRange(
                location: selectedRange.location + prefix.count,
                length: selectedText.count
            ))
        } else {
            let replacement = "\(prefix)\(placeholder)\(suffix)"
            text = nsText.replacingCharacters(in: selectedRange, with: replacement)
            commitText(text, to: tv)
            tv.setSelectedRange(NSRange(
                location: selectedRange.location + prefix.count,
                length: placeholder.count
            ))
        }
    }

    private func toggleLinePrefix(_ prefix: String) {
        guard let tv = textView else { return }
        var text = tv.string
        let selectedRange = tv.selectedRange()
        let nsText = text as NSString
        let lineRange = nsText.lineRange(for: selectedRange)
        let line = nsText.substring(with: lineRange)

        if line.hasPrefix(prefix) {
            let newLine = String(line.dropFirst(prefix.count))
            text = nsText.replacingCharacters(in: lineRange, with: newLine)
            commitText(text, to: tv)
            tv.setSelectedRange(NSRange(
                location: max(lineRange.location, selectedRange.location - prefix.count),
                length: 0
            ))
        } else {
            text = nsText.replacingCharacters(in: NSRange(location: lineRange.location, length: 0), with: prefix)
            commitText(text, to: tv)
            tv.setSelectedRange(NSRange(
                location: selectedRange.location + prefix.count,
                length: 0
            ))
        }
    }

    private func commitText(_ text: String, to textView: NSTextView) {
        htmlContent.wrappedValue = text
        onTextChanged?(text)
        applyHighlighting(to: textView, text: text)
    }

    func insertAtCursor(_ text: String) {
        guard let tv = textView else { return }
        let range = tv.selectedRange()
        let nsString = tv.string as NSString
        let newText = nsString.replacingCharacters(in: range, with: text)
        commitText(newText, to: tv)
        let inserted = (text as NSString).length
        tv.setSelectedRange(NSRange(location: range.location + inserted, length: 0))
    }

    // MARK: - Format Detection

    func detectActiveFormats(in text: String) {
        guard let tv = textView, !text.isEmpty else {
            DispatchQueue.main.async { [weak self] in self?.activeFormats = [] }
            return
        }

        let nsText = text as NSString
        let cursorLocation = min(tv.selectedRange().location, nsText.length)
        let lineRange = nsText.lineRange(for: NSRange(location: cursorLocation, length: 0))
        let line = nsText.substring(with: lineRange)

        var formats: Set<MarkdownFormat> = []

        if line.contains("**") {
            let lineOffset = cursorLocation - lineRange.location
            let before = String(line.prefix(lineOffset))
            let boldMarkersBefore = before.components(separatedBy: "**").count - 1
            if boldMarkersBefore % 2 == 1 { formats.insert(.bold) }
        }

        let lineOffset = cursorLocation - lineRange.location
        let before = String(line.prefix(lineOffset))
        let singleStars = before.replacingOccurrences(of: "**", with: "").filter { $0 == "*" }.count
        if singleStars % 2 == 1 { formats.insert(.italic) }

        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        if trimmedLine.hasPrefix("#") { formats.insert(.heading) }
        if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") { formats.insert(.list) }

        DispatchQueue.main.async { [weak self] in
            self?.activeFormats = formats
        }
    }
}
#endif
