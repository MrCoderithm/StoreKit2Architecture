//
//  StoreView.swift
//  StoreKit2Architecture
//
//  Created by Ali Muhammad on 2026-01-18.
//

import SwiftUI
import StoreKit
import UIKit

struct StoreView: View {
    @EnvironmentObject var vm: StoreViewModel
    @Binding var showingStore: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {

                    StoreSection(
                        title: "Non-Consumables",
                        subtitle: "Pay once, keep forever",
                        systemImage: "infinity",
                        products: vm.nonConsumables
                    )

                    StoreSection(
                        title: "Consumables",
                        subtitle: "Use as needed",
                        systemImage: "ticket",
                        products: vm.consumables
                    )

                    StoreSection(
                        title: "Non-Renewables",
                        subtitle: "Access for a fixed period",
                        systemImage: "calendar",
                        products: vm.nonRenewables
                    )

                    StoreSection(
                        title: "Subscriptions",
                        subtitle: "Auto-renewing access",
                        systemImage: "arrow.triangle.2.circlepath",
                        products: vm.autoRenewables
                    )

                    // Account actions
                    accountButtons
                        .padding(.top, 8)

                    redeemCodeButton
                        .padding(.top, 8)

                    restorePurchases
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Store")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { showingStore = false }
                }
            }
        }
        .alert(vm.alertMessage, isPresented: $vm.isAlertShowing) {
            Button("OK", role: .cancel) { }
        }
    }

    private var restorePurchases: some View {
        Button {
            Task { try? await AppStore.sync() }
        } label: {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Restore Purchases")
                Spacer()
            }
            .font(.headline)
            .padding(14)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var redeemCodeButton: some View {
        Button {
            vm.presentPromoCodeRedemption()
        } label: {
            HStack {
                Image(systemName: "tag")
                Text("Redeem Promo Code")
                Spacer()
            }
            .font(.headline)
            .padding(14)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var accountButtons: some View {
        VStack(spacing: 12) {
            Button {
                vm.showManageSubscriptions()
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle")
                    Text("Manage Subscriptions / Cancel")
                    Spacer()
                }
                .font(.headline)
                .padding(14)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button {
                vm.requestRefund(productID: "subscription.yearly")
            } label: {
                HStack {
                    Image(systemName: "arrow.uturn.backward")
                    Text("Request Refund (Yearly)")
                    Spacer()
                }
                .font(.headline)
                .padding(14)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

/// A reusable section container
private struct StoreSection: View {
    @EnvironmentObject var vm: StoreViewModel

    let title: String
    let subtitle: String
    let systemImage: String
    let products: [Product]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.title2.weight(.bold))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.bottom, 6)

            if products.isEmpty {
                Text("No products available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 12) {
                    ForEach(products, id: \.self) { product in
                        // Force view updates off VM state changes by making it depend on VM helpers
                        ProductRow(product: product)
                    }
                }
            }
        }
    }
}

private struct ProductRow: View {
    @EnvironmentObject var vm: StoreViewModel
    let product: Product

    var body: some View {
        ProductView(product: product)
            // These make SwiftUI re-render the row when purchased/pending/balance changes.
            .id(rowIdentity)
    }

    private var rowIdentity: String {
        // Any change here will cause the row to rebuild.
        let purchased = vm.isPurchased(product)
        let pending = vm.isPending(product.id)
        let balance = vm.consumableBalance(productID: product.id)
        return "\(product.id)|p:\(purchased)|pend:\(pending)|bal:\(balance)"
    }
}
