#if os(macOS)
import SwiftUI
import AppKit

/// NSViewRepresentable that wraps NSTextView with live inline markdown highlighting.
/// Serves as the macOS equivalent of RichTextEditor.
struct MacEditorView: NSViewRepresentable {
    @Binding var htmlContent: String
    var onLinkTapped: ((String) -> Void)?
    var onTextChanged: ((String) -> Void)?
    @Environment(\.colorScheme) var colorScheme

    /// Shared coordinator reference so toolbar actions can reach the text view.
    class Shared: ObservableObject {
        weak var coordinator: MacTextViewCoordinator?
        @Published var activeFormats: Set<MarkdownFormat> = []
    }

    var shared: Shared?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.textColor = NSColor(Color.havenTextPrimary)
        textView.insertionPointColor = NSColor(Color.havenAccent)
        textView.textContainerInset = NSSize(width: 0, height: 12)
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.delegate = context.coordinator

        // Store references
        context.coordinator.textView = textView
        shared?.coordinator = context.coordinator

        scrollView.documentView = textView

        // Apply initial highlighting if content exists
        if !htmlContent.isEmpty {
            context.coordinator.applyHighlighting(to: textView, text: htmlContent)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Only update if content changed externally (not during editing)
        if context.coordinator.isEditing { return }

        let currentText = textView.string
        if currentText != htmlContent {
            context.coordinator.applyHighlighting(to: textView, text: htmlContent)
        }

        // Sync activeFormats to shared
        let formats = context.coordinator.activeFormats
        if shared?.activeFormats != formats {
            shared?.activeFormats = formats
        }
    }

    func makeCoordinator() -> MacTextViewCoordinator {
        let coordinator = MacTextViewCoordinator(
            htmlContent: $htmlContent,
            onTextChanged: onTextChanged,
            onLinkTapped: onLinkTapped
        )
        return coordinator
    }
}
#endif
