import SwiftUI

struct WikiLinkAutocompleteView: View {
    let suggestions: [Note]
    let onSelect: (Note) -> Void

    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                Text("Link to note")
                    .font(.havenCaption)
                    .foregroundColor(Color.havenTextSecondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, note in
                    Button {
                        onSelect(note)
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.caption)
                                .foregroundColor(Color.havenAccent)
                            Text(note.title.isEmpty ? "Untitled" : note.title)
                                .font(.havenBody)
                                .foregroundColor(Color.havenTextPrimary)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(index == selectedIndex ? Color.havenAccent.opacity(0.08) : Color.clear)
                    }
                    .accessibilityLabel("\(note.title.isEmpty ? "Untitled" : note.title), link suggestion")

                    if index < suggestions.count - 1 {
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
            .onKeyPress(.upArrow) {
                selectedIndex = max(0, selectedIndex - 1)
                return .handled
            }
            .onKeyPress(.downArrow) {
                selectedIndex = min(suggestions.count - 1, selectedIndex + 1)
                return .handled
            }
            .onKeyPress(.return) {
                if suggestions.indices.contains(selectedIndex) {
                    onSelect(suggestions[selectedIndex])
                }
                return .handled
            }
        }
        .onChange(of: suggestions) { _, _ in
            selectedIndex = 0
        }
    }
}
