/// Formatting states detectable at the cursor position.
/// Shared between iOS (RichTextCoordinator) and macOS (MacTextViewCoordinator).
enum MarkdownFormat: Hashable {
    case bold, italic, heading, list
}
