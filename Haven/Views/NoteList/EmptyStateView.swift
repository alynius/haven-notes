import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundStyle(.havenPrimary.opacity(0.4))

            Text("No notes yet")
                .font(.havenHeadline)
                .foregroundStyle(.havenTextPrimary)

            Text("Tap + to start writing")
                .font(.havenBody)
                .foregroundStyle(.havenTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
