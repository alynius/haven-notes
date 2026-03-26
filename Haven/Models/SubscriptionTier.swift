import Foundation

enum SubscriptionProductID: String, CaseIterable {
    case monthly = "com.haven.pro.monthly"
    case yearly = "com.haven.pro.yearly"
}

struct SubscriptionTier {
    let productID: SubscriptionProductID
    let displayName: String
    let price: String
    let period: String

    static let monthly = SubscriptionTier(
        productID: .monthly,
        displayName: "Haven Pro Monthly",
        price: "$1.99",
        period: "month"
    )

    static let yearly = SubscriptionTier(
        productID: .yearly,
        displayName: "Haven Pro Yearly",
        price: "$19.99",
        period: "year"
    )
}
