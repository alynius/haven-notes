import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var container: DependencyContainer
    @State private var currentPage = 0
    @State private var appeared = false
    @State private var showPaywall = false

    // 6 pages: Hook → Problem → Solution → Features → Trust → CTA
    private let pages: [OnboardingPage] = [
        // Page 1: HOOK — emotional, aspirational
        OnboardingPage(
            icon: "brain.head.profile",
            secondaryIcon: "sparkles",
            iconColor: Color.havenPrimary,
            accentColor: Color.havenPrimary,
            title: "Your second brain,\nbuilt for clarity",
            description: "A calm space where your best thinking happens. No distractions. No algorithms. Just you and your ideas."
        ),
        // Page 2: PROBLEM — agitate the pain
        OnboardingPage(
            icon: "exclamationmark.icloud",
            secondaryIcon: nil,
            iconColor: Color.havenTextSecondary,
            accentColor: Color.havenTextSecondary,
            title: "Your notes deserve\nbetter",
            description: "Bloated apps. Slow performance. AI reading everything you write. Your ideas are trapped in tools that don't respect them."
        ),
        // Page 3: FEATURE — Markdown editor
        OnboardingPage(
            icon: "pencil.and.outline",
            secondaryIcon: "number",
            iconColor: Color.havenPrimary,
            accentColor: Color.havenPrimary,
            title: "Write with\nreal formatting",
            description: "**Bold**, *italic*, # headings, and `code` — all rendered live as you type. No buttons to click. Just write."
        ),
        // Page 4: FEATURE — Knowledge graph
        OnboardingPage(
            icon: "point.3.connected.trianglepath.dotted",
            secondaryIcon: "link",
            iconColor: Color.havenAccent,
            accentColor: Color.havenAccent,
            title: "See how your\nideas connect",
            description: "Link notes with [[wiki links]]. Watch your knowledge graph grow. Discover connections you didn't know existed."
        ),
        // Page 5: TRUST — privacy & security
        OnboardingPage(
            icon: "lock.shield",
            secondaryIcon: "checkmark.shield",
            iconColor: Color.havenPrimary,
            accentColor: Color.havenPrimary,
            title: "Private.\nEnd to end.",
            description: "Notes live on your device. Optional sync is encrypted with AES-256. Not even Haven can read your notes."
        ),
        // Page 6: SOCIAL PROOF + CTA
        OnboardingPage(
            icon: "heart.fill",
            secondaryIcon: nil,
            iconColor: Color.havenAccent,
            accentColor: Color.havenAccent,
            title: "Made for people\nwho think deeply",
            description: "Haven is built by one person who was tired of bloated note apps. No venture capital. No data harvesting. Just craft."
        ),
    ]

    private var isLastPage: Bool { currentPage == pages.count - 1 }

    var body: some View {
        ZStack {
            Color.havenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: Haven wordmark + Skip
                HStack {
                    Text("Haven")
                        .font(.system(.title3, design: .serif).weight(.semibold))
                        .foregroundColor(Color.havenPrimary)
                        .opacity(appeared ? 1 : 0)
                        .offset(x: appeared ? 0 : -20)

                    Spacer()

                    if !isLastPage {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Skip")
                                .font(.havenBody)
                                .foregroundColor(Color.havenTextSecondary)
                        }
                        .accessibilityIdentifier("onboarding_button_skip")
                    }
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.lg)
                .animation(.easeInOut(duration: 0.2), value: currentPage)

                // Pages
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index], pageIndex: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Progress bar (thin, warm)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.havenPrimary.opacity(0.1))
                            .frame(height: 4)

                        Capsule()
                            .fill(Color.havenPrimary)
                            .frame(width: geo.size.width * CGFloat(currentPage + 1) / CGFloat(pages.count), height: 4)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, Spacing.xxl)
                .padding(.bottom, Spacing.xl)

                // Bottom button
                Group {
                    if isLastPage {
                        // Final: prominent Get Started → leads to paywall or app
                        VStack(spacing: Spacing.md) {
                            Button {
                                // Complete onboarding first, then offer paywall
                                completeOnboarding()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showPaywall = true
                                }
                            } label: {
                                HStack(spacing: Spacing.sm) {
                                    Text("Start Writing")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.body.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.lg)
                                .background(Color.havenPrimary)
                                .clipShape(.rect(cornerRadius: CornerRadius.md))
                            }
                            .accessibilityIdentifier("onboarding_button_startWriting")

                            Text("Free to use · Pro unlocks sync")
                                .font(.caption)
                                .foregroundColor(Color.havenTextSecondary)
                        }
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Text("Continue")
                                Image(systemName: "arrow.right")
                                    .font(.caption.weight(.semibold))
                            }
                            .font(.body.weight(.medium))
                            .foregroundColor(Color.havenPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.lg)
                            .background(Color.havenPrimary.opacity(0.08))
                            .clipShape(.rect(cornerRadius: CornerRadius.md))
                        }
                        .accessibilityIdentifier("onboarding_button_continue")
                    }
                }
                .padding(.horizontal, Spacing.xxl)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentPage)
                .padding(.bottom, Spacing.huge)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                appeared = true
            }
        }
        .onChange(of: currentPage) { newPage in
            // Clamp page index to prevent swiping past the last page
            if newPage >= pages.count {
                currentPage = pages.count - 1
            } else if newPage < 0 {
                currentPage = 0
            }
        }
        .sheet(isPresented: $showPaywall) {
            SubscriptionView(viewModel: SubscriptionViewModel(subscriptionManager: container.subscriptionManager))
        }
    }

    private func completeOnboarding() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            hasCompletedOnboarding = true
        }
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}
