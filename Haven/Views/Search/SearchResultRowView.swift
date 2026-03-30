import SwiftUI

struct SearchResultRowView: View {
    let note: Note
    var query: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(highlightedText(note.title.isEmpty ? "Untitled" : note.title))
                .font(.havenBody.weight(.medium))
                .foregroundColor(Color.havenTextPrimary)
                .lineLimit(1)

            if !note.bodyPlaintext.isEmpty {
                Text(highlightedText(note.bodyPlaintext))
                    .font(.havenCaption)
                    .foregroundColor(Color.havenTextSecondary)
                    .lineLimit(3)
            }

            Text(note.updatedAt, style: .relative)
                .font(.caption2)
                .foregroundColor(Color.havenTextSecondary)
        }
        .padding(.vertical, 4)
    }

    private func highlightedText(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        let terms = query.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        for term in terms {
            var searchRange = attributed.startIndex..<attributed.endIndex
            while let range = attributed[searchRange].range(of: term, options: [.caseInsensitive, .diacriticInsensitive]) {
                attributed[range].backgroundColor = Color.havenAccent.opacity(0.15)
                attributed[range].foregroundColor = Color.havenAccent
                searchRange = range.upperBound..<attributed.endIndex
            }
        }
        return attributed
    }
}
