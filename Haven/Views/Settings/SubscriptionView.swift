import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject var viewModel: SubscriptionViewModel

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
                            .foregroundStyle(.havenTextPrimary)

                        Text("Unlock sync and support indie development")
                            .font(.havenBody)
                            .foregroundStyle(.havenTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    // Current status
                    if viewModel.isPro {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.havenAccent)
                            Text("You're a Pro subscriber")
                                .font(.havenBody.weight(.medium))
                                .foregroundStyle(.havenAccent)
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
                        VStack(spacing: 12) {
                            ForEach(viewModel.products, id: \.id) { product in
                                Button {
                                    let productID = SubscriptionProductID(rawValue: product.id)
                                    if let id = productID {
                                        Task { await viewModel.purchase(id) }
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(product.displayName)
                                                .font(.havenBody.weight(.medium))
                                                .foregroundStyle(.havenTextPrimary)
                                            Text(product.description)
                                                .font(.havenCaption)
                                                .foregroundStyle(.havenTextSecondary)
                                        }
                                        Spacer()
                                        Text(product.displayPrice)
                                            .font(.havenBody.weight(.semibold))
                                            .foregroundStyle(.havenPrimary)
                                    }
                                    .padding(16)
                                    .background(Color.havenSurface)
                                    .clipShape(.rect(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.havenBorder, lineWidth: 1)
                                    )
                                }
                                .disabled(viewModel.isPurchasing)
                            }
                        }
                        .padding(.horizontal, 16)

                        Button {
                            Task { await viewModel.restore() }
                        } label: {
                            Text("Restore Purchases")
                                .font(.havenCaption)
                                .foregroundStyle(.havenTextSecondary)
                        }
                        .padding(.top, 8)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.havenCaption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 16)
                    }

                    // Privacy note
                    Text("No AI. No bloat. Just notes.\nYour subscription supports a solo developer.")
                        .font(.caption2)
                        .foregroundStyle(.havenTextSecondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Subscribe")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .overlay {
            if viewModel.isLoading || viewModel.isPurchasing {
                LoadingOverlayView(message: viewModel.isPurchasing ? "Processing..." : "Loading...")
            }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(.havenAccent)
                .frame(width: 24)
            Text(text)
                .font(.havenBody)
                .foregroundStyle(.havenTextPrimary)
        }
    }
}
