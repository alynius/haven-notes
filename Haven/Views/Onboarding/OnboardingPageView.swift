import SwiftUI

struct OnboardingPage {
    let icon: String
    let secondaryIcon: String?  // Optional floating secondary icon
    let iconColor: Color
    let accentColor: Color
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let pageIndex: Int
    @State private var iconVisible = false
    @State private var titleVisible = false
    @State private var descVisible = false
    @State private var floatingOffset: CGFloat = 0
    @State private var ringScale: CGFloat = 0.6
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Visual area — icon with animated rings and floating elements
            ZStack {
                // Outer pulse ring
                Circle()
                    .stroke(page.accentColor.opacity(0.08), lineWidth: 1.5)
                    .frame(width: 220, height: 220)
                    .scaleEffect(ringScale)

                // Middle ring
                Circle()
                    .stroke(page.accentColor.opacity(0.12), lineWidth: 1)
                    .frame(width: 180, height: 180)
                    .scaleEffect(iconVisible ? 1.0 : 0.5)

                // Background circle
                Circle()
                    .fill(page.accentColor.opacity(0.08))
                    .frame(width: 140, height: 140)
                    .scaleEffect(iconVisible ? 1.0 : 0.3)

                // Main icon
                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(page.iconColor)
                    .scaleEffect(iconVisible ? 1.0 : 0.2)
                    .opacity(iconVisible ? 1.0 : 0)
                    .rotationEffect(.degrees(iconVisible ? 0 : -15))

                // Floating secondary icon (if present)
                if let secondaryIcon = page.secondaryIcon {
                    Image(systemName: secondaryIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(page.accentColor.opacity(0.6))
                        .offset(x: 75, y: -55 + floatingOffset)
                        .opacity(iconVisible ? 0.8 : 0)
                        .scaleEffect(iconVisible ? 1.0 : 0.3)
                }
            }
            .frame(height: 240)
            .padding(.bottom, Spacing.xxxl)

            // Title — staggered entry
            Text(page.title)
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundColor(Color.havenTextPrimary)
                .multilineTextAlignment(.center)
                .opacity(titleVisible ? 1.0 : 0)
                .offset(y: titleVisible ? 0 : 24)
                .padding(.bottom, Spacing.md)

            // Description — staggered entry (later than title)
            Text(page.description)
                .font(.havenBody)
                .foregroundColor(Color.havenTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 300)
                .opacity(descVisible ? 1.0 : 0)
                .offset(y: descVisible ? 0 : 16)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Spacing.xxl)
        .onAppear {
            // Staggered animations — icon first, then title, then description
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.05)) {
                iconVisible = true
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.2)) {
                ringScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                titleVisible = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.45)) {
                descVisible = true
            }
            // Floating animation for secondary icon (disabled when Reduce Motion is on)
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.5)) {
                    floatingOffset = -8
                }
            }
        }
        .onDisappear {
            iconVisible = false
            titleVisible = false
            descVisible = false
            ringScale = 0.6
            floatingOffset = 0
        }
    }
}
