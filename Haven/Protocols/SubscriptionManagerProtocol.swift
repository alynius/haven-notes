import Foundation
import StoreKit

enum EntitlementStatus: Equatable {
    case free
    case pro(expiresAt: Date?)
}

protocol SubscriptionManagerProtocol: AnyObject {
    var entitlement: EntitlementStatus { get }
    var availableProducts: [Product] { get }
    func fetchProducts() async throws
    func purchase(_ productID: SubscriptionProductID) async throws -> Transaction
    func restorePurchases() async throws
    func checkEntitlement() async throws
    func listenForTransactionUpdates() async
}
