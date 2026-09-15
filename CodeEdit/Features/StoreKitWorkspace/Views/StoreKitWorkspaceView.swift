//
//  StoreKitWorkspaceView.swift
//  CodeEdit
//
//

import SwiftUI

/// Visual StoreKit configuration editor and in-app purchase simulation workspace.
public struct StoreKitWorkspaceView: View {
    @ObservedObject private var simulation = StoreKitSimulationService.shared
    @State private var selectedProductID: String?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            topToolbar
            Divider()

            HSplitView {
                productsList
                productDetailPane
                transactionsPane
            }
        }
    }

    private var topToolbar: some View {
        HStack(spacing: 12) {
            Image(systemName: "cart.fill")
                .foregroundStyle(.green)
            Text("StoreKit Workspace & Simulation")
                .font(.headline)

            Spacer()

            Toggle("Accelerated Renewals (10s)", isOn: Binding(
                get: { simulation.isAcceleratedRenewalEnabled },
                set: { _ in simulation.toggleAcceleratedRenewals() }
            ))
            .toggleStyle(.switch)
        }
        .padding(8)
    }

    private var productsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Products")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    let newProd = StoreKitProduct(
                        productID: "com.app.product.\(simulation.products.count + 1)",
                        displayName: "New Product",
                        type: .consumable,
                        price: 0.99
                    )
                    simulation.products.append(newProd)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
            }
            .padding(8)

            List(simulation.products, selection: $selectedProductID) { prod in
                VStack(alignment: .leading, spacing: 2) {
                    Text(prod.displayName)
                        .font(.body)
                    Text("\(prod.productID) • $\(String(format: "%.2f", prod.price))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .tag(prod.productID)
            }
        }
        .frame(minWidth: 180, maxWidth: 240)
    }

    private var productDetailPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let prodID = selectedProductID,
               let index = simulation.products.firstIndex(where: { $0.productID == prodID }) {
                Text("Product Details")
                    .font(.headline)

                Text("Product ID")
                    .font(.caption)
                TextField("Product ID", text: $simulation.products[index].productID)
                    .textFieldStyle(.roundedBorder)

                Text("Display Name")
                    .font(.caption)
                TextField("Display Name", text: $simulation.products[index].displayName)
                    .textFieldStyle(.roundedBorder)

                Text("Type")
                    .font(.caption)
                Picker("Type", selection: $simulation.products[index].type) {
                    ForEach(StoreKitProductType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)

                Divider()

                HStack {
                    Button("Simulate Purchase") {
                        _ = simulation.simulatePurchase(productID: prodID)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Simulate Ask-To-Buy") {
                        _ = simulation.simulatePurchase(productID: prodID, askToBuy: true)
                    }
                }

                Spacer()
            } else {
                Text("Select a product to view details.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .frame(minWidth: 240)
    }

    private var transactionsPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Simulated Transactions")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(8)

            List(simulation.transactions) { tx in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tx.productID)
                            .font(.caption.weight(.medium))
                        Spacer()
                        Text(tx.state)
                            .font(.caption2.bold())
                            .foregroundStyle(stateColor(tx.state))
                    }

                    HStack {
                        Button("Refund") {
                            simulation.simulateRefund(transactionID: tx.id)
                        }
                        .buttonStyle(.plain)
                        .font(.caption2)
                        .foregroundStyle(.red)

                        Button("Retry") {
                            simulation.simulateBillingRetry(transactionID: tx.id)
                        }
                        .buttonStyle(.plain)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .frame(minWidth: 200, maxWidth: 260)
    }

    private func stateColor(_ state: String) -> Color {
        switch state {
        case "Purchased", "Renewed": return .green
        case "Pending (Ask-To-Buy)": return .blue
        case "Refunded": return .red
        default: return .orange
        }
    }
}
