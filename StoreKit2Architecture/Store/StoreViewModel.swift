//
//  StoreViewModel.swift
//  StoreKit2Architecture
//
//  Created by Ali Muhammad on 2026-01-18.
//

import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class StoreViewModel: ObservableObject {

    // MARK: - Products from store
    private(set) var nonConsumables: [Product] = []
    private(set) var consumables: [Product] = []
    private(set) var nonRenewables: [Product] = []
    private(set) var autoRenewables: [Product] = []

    // MARK: - Purchased products
    private(set) var purchasedNonConsumables: [Product] = []
    private(set) var purchasedNonRenewables: [Product] = []
    private(set) var purchasedAutoRenewables: [Product] = []

    // MARK: - Consumables (stored locally)
    private(set) var consumableBalances: [String: Int] = [:]

    // MARK: - Pending purchases (per product)
    private(set) var pendingProductIDs: Set<String> = []

    // MARK: - Purchase status + alerts
    private(set) var purchaseStatus: PurchaseStatus = .unknown {
        didSet {
            switch purchaseStatus {
            case .failed(let error):
                alertMessage = "There was an error completing your purchase: \(error.localizedDescription)."
                isAlertShowing = true
            default:
                return
            }
        }
    }

    var isAlertShowing: Bool = false
    var alertMessage: String = ""

    // MARK: - Service (MainActor isolated)
    private let storeDataService: StoreDataService

    // MARK: - Init
    init() {
        // ✅ Now legal because ViewModel is @MainActor too
        self.storeDataService = StoreDataService()
        addSubscribers()
    }

    // MARK: - Subscribers
    private func addSubscribers() {

        Task {
            for await value in storeDataService.$consumables.values {
                self.consumables = value
            }
        }

        Task {
            for await value in storeDataService.$nonConsumables.values {
                self.nonConsumables = value
            }
        }

        Task {
            for await value in storeDataService.$nonRenewables.values {
                self.nonRenewables = value
            }
        }

        Task {
            for await value in storeDataService.$autoRenewables.values {
                self.autoRenewables = value
            }
        }

        Task {
            for await value in storeDataService.$purchasedNonConsumables.values {
                self.purchasedNonConsumables = value
            }
        }

        Task {
            for await value in storeDataService.$purchasedNonRenewables.values {
                self.purchasedNonRenewables = value
            }
        }

        Task {
            for await value in storeDataService.$purchasedAutoRenewables.values {
                self.purchasedAutoRenewables = value
            }
        }

        Task {
            for await value in storeDataService.$purchaseStatus.values {
                self.purchaseStatus = value
            }
        }

        // ✅ Pending states
        Task {
            for await value in storeDataService.$pendingProductIDs.values {
                self.pendingProductIDs = value
            }
        }

        // ✅ Consumable balances
        Task {
            for await value in storeDataService.$consumableBalances.values {
                self.consumableBalances = value
            }
        }
    }

    // MARK: - Actions

    func purchase(product: Product) {
        Task { await storeDataService.purchase(product) }
    }

    func isPending(_ productID: String) -> Bool {
        pendingProductIDs.contains(productID)
    }

    func isPurchased(_ product: Product) -> Bool {
        switch product.type {
        case .nonConsumable:
            return purchasedNonConsumables.contains(where: { $0.id == product.id })
        case .nonRenewable:
            return purchasedNonRenewables.contains(where: { $0.id == product.id })
        case .autoRenewable:
            return purchasedAutoRenewables.contains(where: { $0.id == product.id })
        default:
            return false
        }
    }

    // MARK: - Consumables

    func consumableBalance(productID: String) -> Int {
        // Fast path from published dictionary (reactive)
        if let val = consumableBalances[productID] { return val }
        // ✅ Safe because ViewModel is @MainActor
        return storeDataService.consumableBalance(for: productID)
    }

    @discardableResult
    func consume(productID: String, amount: Int = 1) -> Bool {
        storeDataService.consume(productID: productID, amount: amount)
    }

    // MARK: - Promo Codes / Subscriptions / Refunds

    func presentPromoCodeRedemption() {
        Task { await storeDataService.presentPromoCodeRedemption() }
    }

    func showManageSubscriptions() {
        Task { await storeDataService.showManageSubscriptions() }
    }

    func requestRefund(productID: String) {
        Task { await storeDataService.requestRefund(for: productID) }
    }
}
