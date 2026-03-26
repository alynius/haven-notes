import SwiftUI

struct SearchResultRowView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.title.isEmpty ? "Untitled" : note.title)
                .font(.havenBody.weight(.medium))
                .foregroundStyle(.havenTextPrimary)
                .lineLimit(1)

            if !note.bodyPlaintext.isEmpty {
                Text(note.bodyPlaintext)
                    .font(.havenCaption)
                    .foregroundStyle(.havenTextSecondary)
                    .lineLimit(3)
            }

            Text(note.updatedAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.havenTextSecondary.opacity(0.6))
        }
        .padding(.vertical, 4)
    }
}
