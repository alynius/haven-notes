import SwiftUI

@MainActor
final class ToastManager: ObservableObject {
    @Published var currentToast: ToastItem?

    struct ToastItem: Equatable {
        let message: String
        let icon: String
        let type: ToastView.ToastType
    }

    func show(_ message: String, icon: String = "checkmark.circle", type: ToastView.ToastType = .info) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentToast = ToastItem(message: message, icon: icon, type: type)
        }

        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
            withAnimation(.easeOut(duration: 0.25)) {
                currentToast = nil
            }
        }
    }

    func showSuccess(_ message: String) {
        show(message, icon: "checkmark.circle", type: .success)
    }

    func showError(_ message: String) {
        show(message, icon: "exclamationmark.triangle", type: .error)
    }
}
