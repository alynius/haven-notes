import SwiftUI

struct TagPickerView: View {
    let tags: [Tag]             // Tags on this note
    let allTags: [Tag]          // All tags in the system (for autocomplete)
    let onAdd: (String) -> Void
    let onRemove: (String) -> Void
    @State private var newTagName = ""
    @FocusState private var isFieldFocused: Bool

    // Filtered suggestions: match typed text, exclude already-added tags
    private var suggestions: [Tag] {
        let query = newTagName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return [] }
        let currentTagIDs = Set(tags.map(\.id))
        return allTags.filter { tag in
            !currentTagIDs.contains(tag.id) &&
            tag.name.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Tags")
                .font(.havenCaption)
                .foregroundColor(Color.havenTextSecondary)
                .accessibilityAddTraits(.isHeader)

            // Current tags as chips
            if !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tags) { tag in
                        Button {
                            onRemove(tag.id)
                        } label: {
                            HStack(spacing: 4) {
                                Text("#\(tag.name)")
                                    .font(.havenCaption)
                                    .foregroundColor(Color.havenAccent)
                                Image(systemName: "xmark")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(Color.havenTextSecondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.havenAccent.opacity(0.1))
                            .clipShape(.rect(cornerRadius: 12))
                        }
                        .accessibilityLabel("Remove tag \(tag.name)")
                        .accessibilityHint("Removes this tag from the note")
                        .accessibilityIdentifier("tagPicker_button_removeTag_\(tag.id)")
                    }
                }
            }

            // Add tag field
            HStack {
                TextField("Add tag...", text: $newTagName)
                    .font(.havenBody)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                    .focused($isFieldFocused)
                    .accessibilityIdentifier("tagPicker_textField_newTag")
                    .onSubmit {
                        addCurrentTag()
                    }
                if !newTagName.isEmpty {
                    Button {
                        addCurrentTag()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color.havenAccent)
                    }
                    .accessibilityLabel("Add tag")
                    .accessibilityIdentifier("tagPicker_button_addTag")
                }
            }
            .padding(Spacing.sm)
            .background(Color.havenSurface)
            .clipShape(.rect(cornerRadius: CornerRadius.sm))

            // Autocomplete suggestions
            if !suggestions.isEmpty && isFieldFocused {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions.prefix(5)) { tag in
                        Button {
                            onAdd(tag.name)
                            newTagName = ""
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "tag")
                                    .font(.caption)
                                    .foregroundColor(Color.havenAccent)
                                Text("#\(tag.name)")
                                    .font(.havenBody)
                                    .foregroundColor(Color.havenTextPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .contentShape(Rectangle())
                            .hoverHighlight()
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add tag \(tag.name)")

                        if tag.id != suggestions.prefix(5).last?.id {
                            Divider()
                                .padding(.leading, Spacing.xxl)
                        }
                    }
                }
                .background(Color.havenSurface)
                .clipShape(.rect(cornerRadius: CornerRadius.sm))
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.2), value: suggestions.count)
            }
        }
        .padding(.top, Spacing.md)
    }

    private func addCurrentTag() {
        let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        onAdd(name)
        newTagName = ""
    }
}

// Simple flow layout for tag chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
