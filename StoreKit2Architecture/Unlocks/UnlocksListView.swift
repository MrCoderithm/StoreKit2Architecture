//
//  UnlocksListView.swift
//  StoreKit2Architecture
//
//  Created by Ali Muhammad on 2026-01-18.
//

import SwiftUI

struct UnlocksListView: View {
    @EnvironmentObject var store: StoreViewModel
    @State var vm: UnlocksViewModel
    @State private var showingStore: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    featureGrid
                    architectureCard
                    storeButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .background(background)
            .navigationTitle("StoreKit 2 Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    UnlocksListView(vm: UnlocksViewModel())
        .environmentObject(StoreViewModel())
}

// MARK: - Sections
extension UnlocksListView {

    private var background: some View {
        LinearGradient(
            colors: [
                Color(.systemGroupedBackground),
                Color(.secondarySystemGroupedBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.thinMaterial)
                    Image(systemName: "cart.fill.badge.plus")
                        .font(.system(size: 26, weight: .bold))
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 6) {
                    Text("StoreKit 2 + MVVM")
                        .font(.title2.weight(.bold))
                    Text("A clean architecture demo for purchases, subscriptions, and local unlocks.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Label("StoreKit 2", systemImage: "seal.fill")
                Label("SwiftUI", systemImage: "swift")
                Label("MVVM", systemImage: "square.stack.3d.up.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.10))
        )
    }

    private var featureGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            FeatureTile(
                title: "Purchases",
                subtitle: "Non-consumable + non-renewable",
                icon: "creditcard.fill"
            )
            FeatureTile(
                title: "Subscriptions",
                subtitle: "Auto-renewable status",
                icon: "arrow.triangle.2.circlepath"
            )
            FeatureTile(
                title: "Local Inventory",
                subtitle: "Consumable balance storage",
                icon: "shippingbox.fill"
            )
            FeatureTile(
                title: "UX States",
                subtitle: "Pending, error, restore",
                icon: "clock.badge.checkmark.fill"
            )
        }
    }

    private var architectureCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "flowchart.fill")
                    .font(.title3.weight(.semibold))
                Text("Architecture Overview")
                    .font(.title3.weight(.bold))
                Spacer()
            }

            ArchitectureRow(
                title: "View Layer (SwiftUI)",
                detail: "Pure UI. Reads state from StoreViewModel and triggers intents (buy, restore, redeem)."
            )
            ArchitectureRow(
                title: "ViewModel Layer (MVVM)",
                detail: "Orchestrates UI state and binds StoreDataService publishers to observable properties."
            )
            ArchitectureRow(
                title: "Service Layer (StoreDataService)",
                detail: "Single source of truth for StoreKit 2 calls, transaction updates, verification, and local consumable storage."
            )

            Divider().opacity(0.6)

            Text("Data Flow")
                .font(.headline)

            Text("User taps → ViewModel intent → StoreDataService executes StoreKit 2 → publishes results → ViewModel updates → UI re-renders.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.10))
        )
    }

    private var storeButton: some View {
        Button {
            showingStore.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bag.fill")
                    .font(.headline)
                Text("Open Store")
                    .font(.headline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(.secondary.opacity(0.9))
            }
            .padding(16)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
        }
        .padding(.top, 6)
        .popover(isPresented: $showingStore) {
            StoreView(showingStore: $showingStore)
                .environmentObject(store)
        }
        .presentationCompactAdaptation(.sheet)
    }
}

// MARK: - Small reusable components

private struct FeatureTile: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                Spacer()
            }

            Text(title)
                .font(.headline.weight(.bold))

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.10))
        )
    }
}

private struct ArchitectureRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline.weight(.semibold))
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
