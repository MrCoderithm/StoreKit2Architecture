//
//  SwiftUIView.swift
//  StoreKit2Architecture
//
//  Created by Ali Muhammad on 2026-01-18.
//
import SwiftUI
import StoreKit

struct ProductView: View {
    @EnvironmentObject var vm: StoreViewModel
    @State private var isPurchased: Bool = false
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if isPurchased {
                            Text("Purchased")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }

                    Text(product.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                buyButton
                    .buttonStyle(BuyButtonStyle(isPurchased: isPurchased))
                    .disabled(isPurchased)
            }
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
        .onAppear { isPurchased = vm.isPurchased(product) }
        .onChange(of: [vm.purchasedAutoRenewables,
                       vm.purchasedNonConsumables,
                       vm.purchasedNonRenewables]) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isPurchased = vm.isPurchased(product)
            }
        }
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                Color(.secondarySystemGroupedBackground),
                Color(.systemGroupedBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var buyButton: some View {
        Button {
            vm.purchase(product: product)
        } label: {
            if isPurchased {
                Image(systemName: "checkmark")
                    .font(.headline.weight(.bold))
            } else if product.subscription != nil {
                Text("Subscribe").font(.headline.weight(.semibold))
            } else {
                Text(product.displayPrice).font(.headline.weight(.semibold))
            }
        }
    }
}


#Preview {
    StoreView(showingStore: .constant(true))
        .environmentObject(StoreViewModel())
}
