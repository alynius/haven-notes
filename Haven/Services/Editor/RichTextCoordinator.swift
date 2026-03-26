import SwiftUI
import UIKit

/// Coordinator that bridges UITextView rich text editing with SwiftUI.
/// In production, this would wrap the Infomaniak Rich HTML Editor.
/// For now, it wraps UITextView with basic attributed string support.
struct RichTextEditor: UIViewRepresentable {
    @Binding var htmlContent: String
    var onLinkTapped: ((String) -> Void)?
    var onTextChanged: ((String) -> Void)?

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
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.allowsEditingTextAttributes = true
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // Only update if content changed externally
        if context.coordinator.isEditing { return }
        if textView.text != HTMLSanitizer.stripHTML(htmlContent) {
            textView.text = HTMLSanitizer.stripHTML(htmlContent)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        var isEditing = false

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing = false
        }

        func textViewDidChange(_ textView: UITextView) {
            // For MVP, store as simple HTML wrapping
            let text = textView.text ?? ""
            let html = "<p>\(text.replacingOccurrences(of: "\n", with: "</p><p>"))</p>"
            parent.htmlContent = html
            parent.onTextChanged?(html)
        }
    }
}
