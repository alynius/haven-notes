import SwiftUI

struct NoteRowView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.havenAccent)
                }
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.havenBody.weight(.medium))
                    .foregroundStyle(.havenTextPrimary)
                    .lineLimit(1)
            }

            if !note.bodyPlaintext.isEmpty {
                Text(note.bodyPlaintext)
                    .font(.havenCaption)
                    .foregroundStyle(.havenTextSecondary)
                    .lineLimit(2)
            }

            Text(note.updatedAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.havenTextSecondary.opacity(0.7))
        }
        .padding(.vertical, 4)
    }
}
