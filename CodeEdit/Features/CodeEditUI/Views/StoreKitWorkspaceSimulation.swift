//
//  StoreKitWorkspaceSimulation.swift
//  UniversalIDE
//

import SwiftUI
import Foundation

public enum StoreKitProductType: String, Codable, Sendable {
    case consumable
    case nonConsumable
    case nonRenewingSubscription
    case autoRenewableSubscription
}

public struct StoreKitProduct: Identifiable, Codable, Sendable {
    public var id: String // Product ID
    public var referenceName: String
    public var type: StoreKitProductType
    public var price: Double
    public var subscriptionGroupID: String?

    public init(id: String, referenceName: String, type: StoreKitProductType, price: Double, subscriptionGroupID: String? = nil) {
        self.id = id
        self.referenceName = referenceName
        self.type = type
        self.price = price
        self.subscriptionGroupID = subscriptionGroupID
    }
}

public final class StoreKitParser {
    public static func parseConfigFile(url: URL) -> [StoreKitProduct] {
        return [
            StoreKitProduct(id: "com.ide.pro.monthly", referenceName: "Pro Monthly", type: .autoRenewableSubscription, price: 9.99, subscriptionGroupID: "pro_group"),
            StoreKitProduct(id: "com.ide.credits.100", referenceName: "100 AI Credits", type: .consumable, price: 4.99)
        ]
    }
}

public final class StoreKitSimulationService: @unchecked Sendable {
    public init() {}

    public func simulatePurchase(productID: String) async -> Bool {
        return true
    }

    public func simulateRenewalCycle(subscriptionGroupID: String) async -> String {
        return "Simulated 1-month renewal cycle in 10s."
    }

    public func simulateAskToBuyChallenge(productID: String) async -> String {
        return "Ask-To-Buy prompt dispatched."
    }

    public func decodeJWSReceiptPayload(jwsString: String) -> [String: Any]? {
        return ["product_id": "com.ide.pro.monthly", "status": "active", "expires_date": "2026-10-01"]
    }
}

public struct StoreKitConfigurationEditorView: View {
    @State private var products: [StoreKitProduct] = [
        StoreKitProduct(id: "com.ide.pro.monthly", referenceName: "Pro Monthly", type: .autoRenewableSubscription, price: 9.99),
        StoreKitProduct(id: "com.ide.credits.100", referenceName: "100 AI Credits", type: .consumable, price: 4.99)
    ]

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(".storekit Configuration Editor").font(.headline)
            List(products) { prod in
                HStack {
                    VStack(alignment: .leading) {
                        Text(prod.referenceName).bold()
                        Text(prod.id).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("$\(prod.price, specifier: "%.2f")")
                    Text("(\(prod.type.rawValue))").font(.caption)
                }
            }
        }
        .padding()
    }
}
