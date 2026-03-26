import SwiftUI

struct WikiLinkAutocompleteView: View {
    let suggestions: [Note]
    let onSelect: (Note) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                Text("Link to note")
                    .font(.havenCaption)
                    .foregroundStyle(.havenTextSecondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                ForEach(suggestions) { note in
                    Button {
                        onSelect(note)
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.caption)
                                .foregroundStyle(.havenAccent)
                            Text(note.title.isEmpty ? "Untitled" : note.title)
                                .font(.havenBody)
                                .foregroundStyle(.havenTextPrimary)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .accessibilityLabel("\(note.title.isEmpty ? "Untitled" : note.title), link suggestion")

                    if note.id != suggestions.last?.id {
                        Divider()
                            .background(Color.havenBorder)
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color.havenSurface)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, y: -4)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(suggestions.count) link suggestions")
        }
    }
}
