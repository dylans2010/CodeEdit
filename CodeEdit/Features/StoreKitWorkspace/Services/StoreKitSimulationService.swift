//
//  StoreKitSimulationService.swift
//  CodeEdit
//
//

import Foundation

/// Service managing local StoreKit transaction simulation, renewals, and receipt inspection.
@MainActor
public final class StoreKitSimulationService: ObservableObject {
    public static let shared = StoreKitSimulationService()

    @Published public var products: [StoreKitProduct] = []
    @Published public var transactions: [SimulatedTransaction] = []
    @Published public var isAcceleratedRenewalEnabled: Bool = false
    @Published public var simulatedFailuresEnabled: Bool = false

    private var renewalTimer: Timer?

    public init() {
        self.products = [
            StoreKitProduct(
                productID: "com.editor.pro.monthly",
                displayName: "CodeEdit Pro Monthly",
                type: .autoRenewableSubscription,
                price: 9.99,
                subscriptionDuration: .oneMonth,
                subscriptionGroupID: "group_pro"
            ),
            StoreKitProduct(
                productID: "com.editor.ai.credits",
                displayName: "1,000 AI Credits",
                type: .consumable,
                price: 4.99
            )
        ]
    }

    /// Simulates a purchase approval flow.
    public func simulatePurchase(productID: String, askToBuy: Bool = false) -> SimulatedTransaction {
        let state = askToBuy ? "Pending (Ask-To-Buy)" : "Purchased"
        let transaction = SimulatedTransaction(productID: productID, state: state)
        transactions.append(transaction)
        return transaction
    }

    /// Simulates user refunding an active transaction.
    public func simulateRefund(transactionID: UUID) {
        if let index = transactions.firstIndex(where: { $0.id == transactionID }) {
            var updated = transactions[index]
            updated.state = "Refunded"
            transactions[index] = updated
        }
    }

    /// Simulates subscription entering billing retry state.
    public func simulateBillingRetry(transactionID: UUID) {
        if let index = transactions.firstIndex(where: { $0.id == transactionID }) {
            var updated = transactions[index]
            updated.state = "Billing Retry"
            transactions[index] = updated
        }
    }

    /// Toggles accelerated renewal simulation (triggering renewal every 10 seconds).
    public func toggleAcceleratedRenewals() {
        isAcceleratedRenewalEnabled.toggle()
        renewalTimer?.invalidate()

        if isAcceleratedRenewalEnabled {
            renewalTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleAcceleratedRenewalCycle()
                }
            }
        }
    }

    private func handleAcceleratedRenewalCycle() {
        for sub in products where sub.type == .autoRenewableSubscription {
            let renewTx = SimulatedTransaction(productID: sub.productID, state: "Renewed")
            transactions.append(renewTx)
        }
    }
}
