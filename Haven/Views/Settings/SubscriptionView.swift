import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject var viewModel: SubscriptionViewModel
    var isModal: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.havenBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Haven Pro")
                            .font(.havenContentTitle)
                            .foregroundColor(Color.havenTextPrimary)

                        Text("Unlock sync and support indie development")
                            .font(.havenBody)
                            .foregroundColor(Color.havenTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    // Current status
                    if viewModel.isPro {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(Color.havenAccent)
                            Text("You're a Pro subscriber")
                                .font(.havenBody.weight(.medium))
                                .foregroundColor(Color.havenAccent)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(Color.havenAccent.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 12))
                        .padding(.horizontal, 16)
                    }

                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        featureRow(icon: "arrow.triangle.2.circlepath", text: "Cloud sync across devices")
                        featureRow(icon: "lock.shield", text: "End-to-end encrypted sync")
                        featureRow(icon: "heart", text: "Support indie development")
                        featureRow(icon: "sparkles", text: "Early access to new features")
                    }
                    .padding(.horizontal, 24)

                    // Products
                    if !viewModel.isPro {
                        // Auto-renewal disclosure — shown BEFORE purchase buttons per App Store guidelines
                        Text("Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. Manage in Settings > Apple ID > Subscriptions.")
                            .font(.caption2)
                            .foregroundColor(Color.havenTextSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            ForEach(viewModel.products.sorted { $0.price > $1.price }, id: \.id) { product in
                                let isYearly = product.id == SubscriptionProductID.yearly.rawValue
                                Button {
                                    let productID = SubscriptionProductID(rawValue: product.id)
                                    if let id = productID {
                                        Task { await viewModel.purchase(id) }
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: Spacing.sm) {
                                                Text(product.displayName)
                                                    .font(.havenBody.weight(.medium))
                                                    .foregroundColor(Color.havenTextPrimary)
                                                if isYearly {
                                                    Text("Best value")
                                                        .font(.caption2.weight(.bold))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, Spacing.sm)
                                                        .padding(.vertical, Spacing.xxs)
                                                        .background(
                                                            LinearGradient(
                                                                colors: [Color.havenAccent, Color.havenAccent.opacity(0.8)],
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            )
                                                        )
                                                        .clipShape(.rect(cornerRadius: CornerRadius.xs))
                                                }
                                            }
                                            Text(subscriptionPeriodLabel(for: product))
                                                .font(.havenCaption)
                                                .foregroundColor(Color.havenTextSecondary)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(product.displayPrice)
                                                .font(.havenBody.weight(.semibold))
                                                .foregroundColor(Color.havenPrimary)
                                            Text(isYearly ? "per year" : "per month")
                                                .font(.caption2)
                                                .foregroundColor(Color.havenTextSecondary)
                                        }
                                    }
                                    .padding(16)
                                    .background(Color.havenSurface)
                                    .clipShape(.rect(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isYearly ? Color.havenAccent : Color.havenBorder, lineWidth: isYearly ? 2 : 1)
                                    )
                                }
                                .disabled(viewModel.isPurchasing)
                                .accessibilityHint("Purchases this subscription plan")
                                .accessibilityIdentifier("subscription_button_product_\(product.id)")
                            }
                        }
                        .padding(.horizontal, 16)

                        if isModal {
                            Button {
                                dismiss()
                            } label: {
                                Text("Continue with Haven Free")
                                    .font(.havenBody.weight(.medium))
                                    .foregroundColor(Color.havenTextPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.havenSurface)
                                    .clipShape(.rect(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.havenBorder, lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 16)
                            .accessibilityIdentifier("subscription_button_continueFree")
                        }

                        Button {
                            Task { await viewModel.restore() }
                        } label: {
                            Text("Restore Purchases")
                                .font(.havenCaption)
                                .foregroundColor(Color.havenTextSecondary)
                        }
                        .accessibilityIdentifier("subscription_button_restore")
                        .padding(.top, 4)

                        HStack(spacing: Spacing.lg) {
                            Link("Terms of Use", destination: URL(string: "https://havennotes.app/terms")!)
                            Text("\u{00B7}").foregroundColor(Color.havenTextSecondary)
                            Link("Privacy Policy", destination: URL(string: "https://havennotes.app/privacy")!)
                        }
                        .font(.caption2)
                        .foregroundColor(Color.havenTextSecondary)
                    }

                    if let error = viewModel.errorMessage {
                        VStack(spacing: 8) {
                            Text(error)
                                .font(.havenCaption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                            Button("Try Again") {
                                Task { await viewModel.load() }
                            }
                            .font(.caption)
                            .foregroundColor(Color.havenPrimary)
                        }
                        .padding(.horizontal, 16)
                    }

                    // Privacy note
                    Text("No AI. No bloat. Just notes.\nYour subscription supports a solo developer.")
                        .font(.caption2)
                        .foregroundColor(Color.havenTextSecondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Subscribe")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await viewModel.load()
        }
        .overlay {
            if viewModel.isLoading || viewModel.isPurchasing {
                LoadingOverlayView(message: viewModel.isPurchasing ? "Processing..." : "Loading...")
            }
        }
    }

    private func subscriptionPeriodLabel(for product: Product) -> String {
        if let subscription = product.subscription {
            let unit = subscription.subscriptionPeriod.unit
            let value = subscription.subscriptionPeriod.value
            switch unit {
            case .month: return value == 1 ? "1 month, auto-renewable" : "\(value) months, auto-renewable"
            case .year: return value == 1 ? "1 year, auto-renewable" : "\(value) years, auto-renewable"
            case .week: return value == 1 ? "1 week, auto-renewable" : "\(value) weeks, auto-renewable"
            case .day: return value == 1 ? "1 day, auto-renewable" : "\(value) days, auto-renewable"
            @unknown default: return "Auto-renewable"
            }
        }
        return product.description
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(Color.havenAccent)
                .frame(width: 24)
            Text(text)
                .font(.havenBody)
                .foregroundColor(Color.havenTextPrimary)
        }
    }
}
