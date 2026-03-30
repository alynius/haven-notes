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
