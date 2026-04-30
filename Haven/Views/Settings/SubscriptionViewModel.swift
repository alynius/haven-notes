import SwiftUI
import StoreKit

@MainActor
final class SubscriptionViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var entitlement: EntitlementStatus = .free
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var errorMessage: String?

    private let subscriptionManager: SubscriptionManagerProtocol

    init(subscriptionManager: SubscriptionManagerProtocol) {
        self.subscriptionManager = subscriptionManager
    }

    var isPro: Bool {
        if case .pro = entitlement { return true }
        return false
    }

    func load() async {
        isLoading = true
        do {
            try await subscriptionManager.fetchProducts()
            products = subscriptionManager.availableProducts
            await subscriptionManager.checkEntitlement()
            entitlement = subscriptionManager.entitlement
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func purchase(_ productID: SubscriptionProductID) async {
        isPurchasing = true
        do {
            let _ = try await subscriptionManager.purchase(productID)
            entitlement = subscriptionManager.entitlement
        } catch {
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }

    func restore() async {
        isLoading = true
        do {
            try await subscriptionManager.restorePurchases()
            entitlement = subscriptionManager.entitlement
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
