import SwiftUI
import UIKit

/// Formatting states detectable at the cursor position.
enum MarkdownFormat: Hashable {
    case bold, italic, heading, list
}

/// UIViewRepresentable that wraps UITextView with live inline markdown highlighting.
/// Stores raw markdown text (not HTML). Syntax characters are visible but dimmed.
struct RichTextEditor: UIViewRepresentable {
    @Binding var htmlContent: String  // Now holds raw markdown (field name kept for DB compat)
    var onLinkTapped: ((String) -> Void)?
    var onTextChanged: ((String) -> Void)?

    /// Shared coordinator reference so toolbar actions can reach the text view.
    class Shared: ObservableObject {
        weak var coordinator: Coordinator?
        @Published var activeFormats: Set<MarkdownFormat> = []
    }

    var shared: Shared?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = UIColor(Color.havenTextPrimary)
        textView.tintColor = UIColor(Color.havenAccent)
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 0, bottom: 16, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.widthTracksTextView = true
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.allowsEditingTextAttributes = false
        // Enable link interaction while keeping editing enabled
        textView.isSelectable = true
        textView.dataDetectorTypes = []  // We handle links manually via .link attribute

        // Store references
        context.coordinator.textView = textView
        shared?.coordinator = context.coordinator

        // Apply initial highlighting if content exists
        if !htmlContent.isEmpty {
            context.coordinator.applyHighlighting(to: textView, text: htmlContent)
        }

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // Only update if content changed externally (not during editing)
        if context.coordinator.isEditing { return }

        let currentPlainText = textView.attributedText?.string ?? ""
        if currentPlainText != htmlContent {
            context.coordinator.applyHighlighting(to: textView, text: htmlContent)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        var isEditing = false
        weak var textView: UITextView?

        private var highlighter: MarkdownHighlighter
        private var highlightWorkItem: DispatchWorkItem?
        /// Debounce interval for re-highlighting while typing (seconds).
        private let highlightDebounce: TimeInterval = 0.05

        init(_ parent: RichTextEditor) {
            self.parent = parent
            let theme = MarkdownHighlighter.Theme.haven(
                traitCollection: UITraitCollection.current
            )
            self.highlighter = MarkdownHighlighter(theme: theme)
        }

        // MARK: - UITextViewDelegate

        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing = false
            // Final highlight pass on end editing
            let text = textView.text ?? ""
            applyHighlighting(to: textView, text: text)
        }

        func textViewDidChange(_ textView: UITextView) {
            let text = textView.text ?? ""

            // Update the binding with raw markdown
            parent.htmlContent = text
            parent.onTextChanged?(text)

            // Apply highlighting immediately for responsive feedback
            applyHighlighting(to: textView, text: text)

            // Update active formatting state
            detectActiveFormats(in: text, at: textView.selectedRange)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            let text = textView.text ?? ""
            detectActiveFormats(in: text, at: textView.selectedRange)
        }

        /// Handle taps on links — open in Safari when not actively editing that link
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            // For wiki links, route through the parent callback
            let tappedText = (textView.text as NSString?)?.substring(with: characterRange) ?? ""
            if tappedText.hasPrefix("[[") {
                let title = tappedText.replacingOccurrences(of: "[[", with: "").replacingOccurrences(of: "]]", with: "")
                parent.onLinkTapped?(title)
                return false
            }
            // Open regular URLs in Safari
            UIApplication.shared.open(URL)
            return false
        }

        /// Detect pasted URLs and auto-fetch page title
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Check if the pasted text is a bare URL
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://"),
               let url = URL(string: trimmed),
               trimmed.count > 10,
               !trimmed.contains("\n") {
                // Insert the URL immediately so the user sees it
                // Then fetch the title in the background and replace
                let nsText = (textView.text ?? "") as NSString
                let newText = nsText.replacingCharacters(in: range, with: text)
                commitText(newText, to: textView)
                textView.selectedRange = NSRange(location: range.location + text.count, length: 0)

                // Fetch title in background
                let insertRange = NSRange(location: range.location, length: trimmed.count)
                Task { [weak self] in
                    if let title = await self?.fetchPageTitle(from: url), !title.isEmpty {
                        await MainActor.run {
                            guard let self = self, let textView = self.textView else { return }
                            let current = textView.text ?? ""
                            let nsCurrent = current as NSString
                            // Verify the URL is still at the expected position
                            if insertRange.location + insertRange.length <= nsCurrent.length {
                                let existing = nsCurrent.substring(with: insertRange)
                                if existing == trimmed {
                                    let markdown = "[\(title)](\(trimmed))"
                                    let replaced = nsCurrent.replacingCharacters(in: insertRange, with: markdown)
                                    let cursorPos = insertRange.location + markdown.count
                                    self.commitText(replaced, to: textView)
                                    textView.selectedRange = NSRange(location: cursorPos, length: 0)
                                }
                            }
                        }
                    }
                }
                return false  // We handled the insertion
            }
            return true
        }

        /// Fetch the <title> tag from a URL.
        private func fetchPageTitle(from url: URL) async -> String? {
            do {
                var request = URLRequest(url: url, timeoutInterval: 5)
                request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
                let (data, response) = try await URLSession.shared.data(for: request)

                // Only parse HTML responses
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
                      contentType.contains("text/html") else {
                    return nil
                }

                // Extract <title> from first 16KB of HTML
                let chunk = data.prefix(16384)
                guard let html = String(data: chunk, encoding: .utf8) ?? String(data: chunk, encoding: .ascii) else {
                    return nil
                }

                // Simple regex to extract title
                guard let regex = try? NSRegularExpression(pattern: "<title[^>]*>([^<]+)</title>", options: .caseInsensitive),
                      let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)) else {
                    return nil
                }

                let titleRange = match.range(at: 1)
                guard let swiftRange = Range(titleRange, in: html) else { return nil }
                var title = String(html[swiftRange])

                // Clean up common title artifacts
                title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                // Decode HTML entities
                title = title.replacingOccurrences(of: "&amp;", with: "&")
                    .replacingOccurrences(of: "&lt;", with: "<")
                    .replacingOccurrences(of: "&gt;", with: ">")
                    .replacingOccurrences(of: "&#39;", with: "'")
                    .replacingOccurrences(of: "&quot;", with: "\"")

                // Truncate very long titles
                if title.count > 100 {
                    title = String(title.prefix(97)) + "..."
                }

                return title.isEmpty ? nil : title
            } catch {
                return nil
            }
        }

        // MARK: - Highlighting

        func applyHighlighting(to textView: UITextView, text: String) {
            // Update theme in case dark/light mode changed
            highlighter.updateTheme(
                MarkdownHighlighter.Theme.haven(traitCollection: textView.traitCollection)
            )

            // Save cursor position
            let selectedRange = textView.selectedRange

            let highlighted = highlighter.highlight(text)
            textView.attributedText = highlighted

            // Restore cursor position (clamped to valid range)
            let maxLocation = (textView.text as NSString?)?.length ?? 0
            let safeLocation = min(selectedRange.location, maxLocation)
            let safeLength = min(selectedRange.length, maxLocation - safeLocation)
            textView.selectedRange = NSRange(location: safeLocation, length: safeLength)
        }

        // MARK: - Toolbar Actions

        /// Insert markdown syntax at the current cursor position.
        /// If text is selected, wraps the selection. Otherwise inserts placeholder.
        func insertBold() {
            wrapOrInsert(prefix: "**", suffix: "**", placeholder: "bold")
        }

        func insertItalic() {
            wrapOrInsert(prefix: "*", suffix: "*", placeholder: "italic")
        }

        /// Cycle heading: plain → # → ## → ### → plain
        func insertHeading(level: Int = 1) {
            guard let textView = textView else { return }
            var text = textView.text ?? ""
            let selectedRange = textView.selectedRange
            let nsText = text as NSString
            let lineRange = nsText.lineRange(for: selectedRange)
            let line = nsText.substring(with: lineRange)

            // Detect current heading level
            var currentLevel = 0
            for ch in line {
                if ch == "#" { currentLevel += 1 } else { break }
            }

            // Strip existing heading prefix
            let stripped: String
            if currentLevel > 0 {
                let drop = line.drop(while: { $0 == "#" })
                stripped = String(drop.hasPrefix(" ") ? drop.dropFirst() : drop)
            } else {
                stripped = line
            }

            // Cycle: 0→1, 1→2, 2→3, 3→0
            let nextLevel = currentLevel >= 3 ? 0 : currentLevel + 1
            let newPrefix = nextLevel > 0 ? String(repeating: "#", count: nextLevel) + " " : ""
            let newLine = newPrefix + stripped

            text = nsText.replacingCharacters(in: lineRange, with: newLine)
            commitText(text, to: textView)

            let cursorOffset = selectedRange.location - lineRange.location
            let newCursor = lineRange.location + min(cursorOffset + (newPrefix.count - (currentLevel > 0 ? currentLevel + 1 : 0)), newLine.count)
            textView.selectedRange = NSRange(location: max(lineRange.location, newCursor), length: 0)
        }

        func insertList() {
            toggleLinePrefix("- ")
        }

        func insertCheckbox() {
            toggleLinePrefix("- [ ] ")
        }

        func insertLink() {
            guard let textView = textView else { return }
            let selectedRange = textView.selectedRange
            var text = textView.text ?? ""
            let nsText = text as NSString

            if selectedRange.length > 0 {
                let selectedText = nsText.substring(with: selectedRange)
                let replacement = "[\(selectedText)](url)"
                text = nsText.replacingCharacters(in: selectedRange, with: replacement)
                commitText(text, to: textView)
                let urlStart = selectedRange.location + selectedText.count + 3
                textView.selectedRange = NSRange(location: urlStart, length: 3)
            } else {
                let replacement = "[link](url)"
                text = nsText.replacingCharacters(in: selectedRange, with: replacement)
                commitText(text, to: textView)
                textView.selectedRange = NSRange(location: selectedRange.location + 1, length: 4)
            }
        }

        // MARK: - Private Helpers

        private func wrapOrInsert(prefix: String, suffix: String, placeholder: String) {
            guard let textView = textView else { return }
            let selectedRange = textView.selectedRange
            var text = textView.text ?? ""
            let nsText = text as NSString

            if selectedRange.length > 0 {
                let selectedText = nsText.substring(with: selectedRange)
                let replacement = "\(prefix)\(selectedText)\(suffix)"
                text = nsText.replacingCharacters(in: selectedRange, with: replacement)
                commitText(text, to: textView)
                textView.selectedRange = NSRange(
                    location: selectedRange.location + prefix.count,
                    length: selectedText.count
                )
            } else {
                let replacement = "\(prefix)\(placeholder)\(suffix)"
                text = nsText.replacingCharacters(in: selectedRange, with: replacement)
                commitText(text, to: textView)
                textView.selectedRange = NSRange(
                    location: selectedRange.location + prefix.count,
                    length: placeholder.count
                )
            }
        }

        /// Toggle a line prefix: add if missing, remove if present.
        private func toggleLinePrefix(_ prefix: String) {
            guard let textView = textView else { return }
            var text = textView.text ?? ""
            let selectedRange = textView.selectedRange
            let nsText = text as NSString
            let lineRange = nsText.lineRange(for: selectedRange)
            let line = nsText.substring(with: lineRange)

            if line.hasPrefix(prefix) {
                // Remove prefix
                let newLine = String(line.dropFirst(prefix.count))
                text = nsText.replacingCharacters(in: lineRange, with: newLine)
                commitText(text, to: textView)
                textView.selectedRange = NSRange(
                    location: max(lineRange.location, selectedRange.location - prefix.count),
                    length: 0
                )
            } else {
                // Add prefix
                text = nsText.replacingCharacters(in: NSRange(location: lineRange.location, length: 0), with: prefix)
                commitText(text, to: textView)
                textView.selectedRange = NSRange(
                    location: selectedRange.location + prefix.count,
                    length: 0
                )
            }
        }

        /// Write plain text, update binding, and re-highlight in one step.
        private func commitText(_ text: String, to textView: UITextView) {
            parent.htmlContent = text
            parent.onTextChanged?(text)
            applyHighlighting(to: textView, text: text)
        }

        // MARK: - Format Detection

        /// Detect which markdown formats are active at the current cursor position.
        private func detectActiveFormats(in text: String, at range: NSRange) {
            guard !text.isEmpty else {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.shared?.activeFormats = []
                }
                return
            }

            let nsText = text as NSString
            let cursorLocation = min(range.location, nsText.length)
            let lineRange = nsText.lineRange(for: NSRange(location: cursorLocation, length: 0))
            let line = nsText.substring(with: lineRange)

            var formats: Set<MarkdownFormat> = []

            // Check if cursor is inside bold markers
            if line.contains("**") {
                let lineOffset = cursorLocation - lineRange.location
                let before = String(line.prefix(lineOffset))
                let boldMarkersBefore = before.components(separatedBy: "**").count - 1
                if boldMarkersBefore % 2 == 1 {
                    formats.insert(.bold)
                }
            }

            // Check if cursor is inside italic markers (single *)
            let lineOffset = cursorLocation - lineRange.location
            let before = String(line.prefix(lineOffset))
            let singleStars = before.replacingOccurrences(of: "**", with: "").filter { $0 == "*" }.count
            if singleStars % 2 == 1 {
                formats.insert(.italic)
            }

            // Check if line starts with heading
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("#") {
                formats.insert(.heading)
            }

            // Check if line starts with list marker
            if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                formats.insert(.list)
            }

            // Defer @Published update to avoid "publishing changes from within view updates"
            DispatchQueue.main.async { [weak self] in
                self?.parent.shared?.activeFormats = formats
            }
        }
    }
}
