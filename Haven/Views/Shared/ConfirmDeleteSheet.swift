import SwiftUI

struct ConfirmDeleteSheet: View {
    let title: String
    let message: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.havenHeadline)
                .foregroundStyle(.havenTextPrimary)

            Text(message)
                .font(.havenBody)
                .foregroundStyle(.havenTextSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Cancel") { onCancel() }
                    .font(.havenBody)
                    .foregroundStyle(.havenTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.havenSurface)
                    .clipShape(.rect(cornerRadius: 8))

                Button("Delete") { onConfirm() }
                    .font(.havenBody.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.85))
                    .clipShape(.rect(cornerRadius: 8))
            }
        }
        .padding(24)
    }
}
