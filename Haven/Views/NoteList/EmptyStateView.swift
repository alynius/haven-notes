import SwiftUI

struct EmptyStateView: View {
    var filter: NoteFilter = .allNotes
    var onCreateNote: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private var iconName: String {
        switch filter {
        case .allNotes: return "note.text"
        case .folder: return "folder"
        case .tag: return "tag"
        }
    }

    private var headline: String {
        switch filter {
        case .allNotes:
            return "No notes yet"
        case .folder(_, let name):
            return "\"\(name)\" is empty"
        case .tag(_, let name):
            return "No notes tagged \"\(name)\""
        }
    }

    private var bodyText: String {
        switch filter {
        case .allNotes:
            return "Your thoughts are safe here.\nTap below to start writing."
        case .folder:
            return "Add the first note to this folder."
        case .tag:
            return "Open or create a note and add this tag to organize it here."
        }
    }

    private var ctaLabel: String? {
        switch filter {
        case .allNotes: return "Create Note"
        case .folder: return "Create Note Here"
        case .tag: return nil  // tags can't be assigned without an existing note context
        }
    }

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Image(systemName: iconName)
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.havenPrimary.opacity(0.4))
                .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.3), isActive: !reduceMotion)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.sm) {
                Text(headline)
                    .font(.havenHeadline)
                    .foregroundColor(Color.havenTextPrimary)
                    .multilineTextAlignment(.center)

                Text(bodyText)
                    .font(.havenBody)
                    .foregroundColor(Color.havenTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            if let onCreateNote, let ctaLabel {
                Button(action: onCreateNote) {
                    Text(ctaLabel)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: 220)
                        .padding(.vertical, Spacing.md)
                        .background(Color.havenPrimary)
                        .clipShape(.rect(cornerRadius: CornerRadius.sm))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("emptyState_button_createNote")
                .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xxl)
    }
}
