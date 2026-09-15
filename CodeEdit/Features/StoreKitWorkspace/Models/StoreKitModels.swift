//
//  StoreKitModels.swift
//  CodeEdit
//
//

import Foundation

/// Supported StoreKit product types.
public enum StoreKitProductType: String, Codable, CaseIterable, Sendable {
    case consumable = "Consumable"
    case nonConsumable = "Non-Consumable"
    case nonRenewingSubscription = "Non-Renewing Subscription"
    case autoRenewableSubscription = "Auto-Renewable Subscription"
}

/// Subscription durations for Auto-Renewable Subscriptions.
public enum SubscriptionDuration: String, Codable, CaseIterable, Sendable {
    case oneWeek = "P1W"
    case oneMonth = "P1M"
    case twoMonths = "P2M"
    case threeMonths = "P3M"
    case sixMonths = "P6M"
    case oneYear = "P1Y"

    public var displayName: String {
        switch self {
        case .oneWeek: return "1 Week"
        case .oneMonth: return "1 Month"
        case .twoMonths: return "2 Months"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .oneYear: return "1 Year"
        }
    }
}

/// Simulated StoreKit product model.
public struct StoreKitProduct: Identifiable, Codable, Sendable {
    public var id: String { productID }
    public var productID: String
    public var displayName: String
    public var type: StoreKitProductType
    public var price: Double
    public var subscriptionDuration: SubscriptionDuration?
    public var subscriptionGroupID: String?

    public init(
        productID: String,
        displayName: String,
        type: StoreKitProductType,
        price: Double,
        subscriptionDuration: SubscriptionDuration? = nil,
        subscriptionGroupID: String? = nil
    ) {
        self.productID = productID
        self.displayName = displayName
        self.type = type
        self.price = price
        self.subscriptionDuration = subscriptionDuration
        self.subscriptionGroupID = subscriptionGroupID
    }
}

/// Simulated in-app purchase transaction.
public struct SimulatedTransaction: Identifiable, Codable, Sendable {
    public let id: UUID
    public let productID: String
    public let purchaseDate: Date
    public var state: String // "Purchased", "Pending (Ask-To-Buy)", "Refunded", "Revoked", "Billing Retry"
    public let jwsRepresentation: String

    public init(
        productID: String,
        state: String = "Purchased"
    ) {
        self.id = UUID()
        self.productID = productID
        self.purchaseDate = Date()
        self.state = state
        self.jwsRepresentation = "eyJhbGciOiJFUzI1NiIsIng1YyI6WyJNSUlC...\""
    }
}
