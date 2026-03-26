import SwiftUI

struct LoadingOverlayView: View {
    var message: String = "Loading..."

    var body: some View {
        ZStack {
            Color.primary.opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .tint(Color.havenPrimary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.regularMaterial)
            .clipShape(.rect(cornerRadius: 12))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(message)
            .accessibilityAddTraits(.updatesFrequently)
        }
    }
}
