import SwiftUI

struct ToastView: View {
    let message: String
    let icon: String
    let type: ToastType

    enum ToastType {
        case success, error, info

        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return Color.havenAccent
            }
        }
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.callout.weight(.semibold))
                .foregroundColor(type.color)

            Text(message)
                .font(.havenCaption)
                .foregroundColor(Color.havenTextPrimary)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(.regularMaterial)
        .clipShape(.capsule)
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
