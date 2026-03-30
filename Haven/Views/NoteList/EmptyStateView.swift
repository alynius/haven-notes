import SwiftUI

struct EmptyStateView: View {
    var onCreateNote: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Image(systemName: "note.text")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.havenPrimary.opacity(0.4))
                .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.3))

            VStack(spacing: Spacing.sm) {
                Text("No notes yet")
                    .font(.havenHeadline)
                    .foregroundColor(Color.havenTextPrimary)

                Text("Your thoughts are safe here.\nTap below to start writing.")
                    .font(.havenBody)
                    .foregroundColor(Color.havenTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            if let onCreateNote {
                Button(action: onCreateNote) {
                    Text("Create Note")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: 200)
                        .padding(.vertical, Spacing.md)
                        .background(Color.havenPrimary)
                        .clipShape(.rect(cornerRadius: CornerRadius.sm))
                }
                .buttonStyle(.plain)
                .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xxl)
    }
}
