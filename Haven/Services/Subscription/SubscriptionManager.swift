import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject, SubscriptionManagerProtocol {
    @Published private(set) var entitlement: EntitlementStatus = .free
    @Published private(set) var availableProducts: [Product] = []

    private var transactionListener: Task<Void, Never>?

    init() {
        // Start listening for transactions immediately
        transactionListener = Task {
            await listenForTransactionUpdates()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    func fetchProducts() async throws {
        let productIDs = SubscriptionProductID.allCases.map(\.rawValue)
        availableProducts = try await Product.products(for: Set(productIDs))
            .sorted { $0.price < $1.price }
    }

    func purchase(_ productID: SubscriptionProductID) async throws -> Transaction {
        guard let product = availableProducts.first(where: { $0.id == productID.rawValue }) else {
            throw SubscriptionError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await checkEntitlement()
            return transaction

        case .userCancelled:
            throw SubscriptionError.userCancelled

        case .pending:
            throw SubscriptionError.pending

        @unknown default:
            throw SubscriptionError.unknown
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await checkEntitlement()
    }

    func checkEntitlement() async {
        // Check for active subscription
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productType == .autoRenewable {
                    entitlement = .pro(expiresAt: transaction.expirationDate)
                    return
                }
            }
        }
        entitlement = .free
    }

    func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await transaction.finish()
                await checkEntitlement()
            }
        }
    }

    // MARK: - Private

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw SubscriptionError.verificationFailed
        }
    }
}

enum SubscriptionError: Error, LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case verificationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound: return "Product not found"
        case .userCancelled: return "Purchase cancelled"
        case .pending: return "Purchase pending approval"
        case .verificationFailed: return "Purchase verification failed"
        case .unknown: return "Unknown error"
        }
    }
}
