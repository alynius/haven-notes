import SwiftUI

struct NoteRowView: View {
    let note: Note
    var folderName: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundColor(Color.havenAccent)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel("Pinned")
                }
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.havenBody.weight(.medium))
                    .foregroundColor(Color.havenTextPrimary)
                    .lineLimit(1)

                Spacer()

                // Folder badge
                if let folderName = folderName {
                    HStack(spacing: 3) {
                        Image(systemName: "folder.fill")
                            .font(.caption2)
                        Text(folderName)
                            .font(.caption2)
                    }
                    .foregroundColor(Color.havenPrimary.opacity(0.85))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.havenPrimary.opacity(0.08))
                    .clipShape(.rect(cornerRadius: CornerRadius.xs))
                }
            }

            if !note.bodyPlaintext.isEmpty {
                Text(note.bodyPlaintext)
                    .font(.havenCaption)
                    .foregroundColor(Color.havenTextSecondary)
                    .lineLimit(2)
            }

            Text(note.updatedAt, style: .relative)
                .font(.caption2)
                .foregroundColor(Color.havenTextSecondary)
        }
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
    }
}
