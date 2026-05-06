import SwiftUI

struct SkeletonView: View {
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.xs)
            .fill(Color.havenBorder.opacity(0.5))
            .overlay(
                Group {
                    if !reduceMotion {
                        RoundedRectangle(cornerRadius: CornerRadius.xs)
                            .fill(
                                LinearGradient(
                                    colors: [.clear, Color.havenSurface.opacity(0.8), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: isAnimating ? 200 : -200)
                    }
                }
            )
            .clipped()
            .onAppear {
                if !reduceMotion {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
            }
    }
}

struct SkeletonListRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SkeletonView()
                .frame(width: 180, height: 16)
            SkeletonView()
                .frame(height: 12)
            SkeletonView()
                .frame(width: 120, height: 12)
        }
        .padding(.vertical, Spacing.sm)
    }
}
