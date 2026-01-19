//
//  StoreDataService.swift
//  StoreKit2Architecture
//
//  Created by Ali Muhammad on 2026-01-18.
//

import Foundation
import StoreKit
import UIKit

enum StoreKitError: Error {
    case failedVerification
    case unknownError
}

enum PurchaseStatus {
    case success(String)
    case pending
    case cancelled
    case failed(Error)
    case unknown
}

typealias Transaction = StoreKit.Transaction
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

@MainActor
final class StoreDataService: ObservableObject {

    // MARK: - Products from the store
    @Published private(set) var nonConsumables: [Product] = []
    @Published private(set) var consumables: [Product] = []
    @Published private(set) var nonRenewables: [Product] = []
    @Published private(set) var autoRenewables: [Product] = []

    // MARK: - Purchased products
    @Published private(set) var purchasedNonConsumables: [Product] = []
    @Published private(set) var purchasedNonRenewables: [Product] = []
    @Published private(set) var purchasedAutoRenewables: [Product] = []
    @Published private(set) var subscriptionGroupStatus: RenewalState?

    // MARK: - Pending purchases (per product id)
    @Published private(set) var pendingProductIDs: Set<String> = []

    // MARK: - Consumables stored locally (AppStorage/UserDefaults keys)
    private let defaults = UserDefaults.standard
    private let consumableKeyPrefix = "consumable.balance."
    @Published private(set) var consumableBalances: [String: Int] = [:]

    // Product IDs
    private let productsIds = [
        "nonconsumable.lifetime",
        "consumable.week",
        "subscription.yearly",
        "nonrenewable.year"
    ]

    // Used for educational purposes
    @Published private(set) var purchaseStatus: PurchaseStatus = .unknown {
        didSet {
            print("--------------------")
            print("Purchase Status: \(purchaseStatus)")
            print("--------------------")
        }
    }

    /// Background task that listens for Store updates
    private(set) var transactionListener: Task<Void, Error>?

    // MARK: - Init / Deinit

    init() {
        transactionListener = transactionStatusStream()
        Task {
            await retrieveProducts()
            await retrievePurchasedProducts()
            loadConsumableBalances()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product loading

    /// Get products from Store
    func retrieveProducts() async {
        do {
            let storeProducts = try await Product.products(for: productsIds)

            var nonConsumables: [Product] = []
            var consumables: [Product] = []
            var nonRenewables: [Product] = []
            var autoRenewables: [Product] = []

            for product in storeProducts {
                switch product.type {
                case .nonConsumable:
                    nonConsumables.append(product)
                case .consumable:
                    consumables.append(product)
                case .nonRenewable:
                    nonRenewables.append(product)
                case .autoRenewable:
                    autoRenewables.append(product)
                default:
                    break
                }
            }

            self.nonConsumables = sortByPrice(nonConsumables)
            self.consumables = sortByPrice(consumables)
            self.nonRenewables = sortByPrice(nonRenewables)
            self.autoRenewables = sortByPrice(autoRenewables)

            print("Store products finished loading.")
        } catch {
            print("Couldn't load products from the App Store: \(error)")
        }
    }

    /// Get purchased products (non-consumables / non-renewables / auto-renewables)
    func retrievePurchasedProducts() async {
        var purchasedNonConsumables: [Product] = []
        var purchasedNonRenewables: [Product] = []
        var purchasedAutoRenewables: [Product] = []

        for await verificationResult in Transaction.currentEntitlements {
            do {
                let transaction = try verifyPurchase(verificationResult)
                print("Retrieved entitlement:: \(transaction.productID)")

                switch transaction.productType {
                case .nonConsumable:
                    if let product = nonConsumables.first(where: { $0.id == transaction.productID }) {
                        purchasedNonConsumables.append(product)
                    }

                case .nonRenewable:
                    if let product = nonRenewables.first(where: { $0.id == transaction.productID }) {
                        // Non-renewable logic: expires 1 year after purchase
                        let currentDate = Date()
                        guard let expirationDate = Calendar(identifier: .gregorian).date(
                            byAdding: DateComponents(year: 1),
                            to: transaction.purchaseDate
                        ) else {
                            print("Could not determine expiration date.")
                            break
                        }

                        if currentDate < expirationDate {
                            purchasedNonRenewables.append(product)
                        }
                    }

                case .autoRenewable:
                    if let product = autoRenewables.first(where: { $0.id == transaction.productID }) {
                        purchasedAutoRenewables.append(product)
                    }

                default:
                    break
                }
            } catch {
                print("Entitlement verification failed: \(error)")
            }
        }

        self.purchasedNonConsumables = purchasedNonConsumables
        self.purchasedNonRenewables = purchasedNonRenewables
        self.purchasedAutoRenewables = purchasedAutoRenewables

        // Subscription group status (applies to the whole group)
        subscriptionGroupStatus = try? await autoRenewables.first?.subscription?.status.first?.state
    }

    // MARK: - Consumables storage (AppStorage / UserDefaults keys)

    private func loadConsumableBalances() {
        var dict: [String: Int] = [:]
        for id in productsIds {
            let key = consumableKeyPrefix + id
            let val = defaults.integer(forKey: key)
            if val > 0 { dict[id] = val }
        }
        self.consumableBalances = dict
    }

    func consumableBalance(for productID: String) -> Int {
        defaults.integer(forKey: consumableKeyPrefix + productID)
    }

    private func setConsumableBalance(productID: String, value: Int) {
        defaults.set(max(0, value), forKey: consumableKeyPrefix + productID)
        loadConsumableBalances()
    }

    private func addConsumable(productID: String, amount: Int = 1) {
        let current = consumableBalance(for: productID)
        setConsumableBalance(productID: productID, value: current + max(0, amount))
    }

    /// Call this from app logic when user spends a token/credit.
    /// Returns true if spend succeeded.
    func consume(productID: String, amount: Int = 1) -> Bool {
        let current = consumableBalance(for: productID)
        let amt = max(0, amount)
        guard current >= amt else { return false }
        setConsumableBalance(productID: productID, value: current - amt)
        return true
    }

    // MARK: - Purchasing

    /// Make a purchase + handle pending / success / cancel + consumables storage
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                do {
                    let transaction = try verifyPurchase(verification)

                    // Clear pending for this product (if it was pending)
                    pendingProductIDs.remove(product.id)

                    // If consumable, persist locally (since it won't appear in entitlements)
                    if transaction.productType == .consumable {
                        addConsumable(productID: transaction.productID, amount: 1)
                    }

                    await retrievePurchasedProducts()
                    await transaction.finish()

                    purchaseStatus = .success(transaction.productID)
                } catch {
                    pendingProductIDs.remove(product.id)
                    purchaseStatus = .failed(error)
                }

            case .pending:
                pendingProductIDs.insert(product.id)
                purchaseStatus = .pending

            case .userCancelled:
                pendingProductIDs.remove(product.id)
                purchaseStatus = .cancelled

            @unknown default:
                pendingProductIDs.remove(product.id)
                purchaseStatus = .failed(StoreKitError.unknownError)
            }
        } catch {
            pendingProductIDs.remove(product.id)
            purchaseStatus = .failed(error)
        }
    }

    // MARK: - Promo Codes

    /// Presents the system promo/offer code redemption sheet.
    /// Call from UI (button) via ViewModel.
    func presentPromoCodeRedemption() async {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            purchaseStatus = .failed(StoreKitError.unknownError)
            return
        }

        if #available(iOS 16.0, *) {
            do {
                try await AppStore.presentOfferCodeRedeemSheet(in: scene)
            } catch {
                purchaseStatus = .failed(error)
            }
        } else {
            // iOS 14–15 fallback (StoreKit 1)
            SKPaymentQueue.default().presentCodeRedemptionSheet()
        }
    }


    // MARK: - Cancellation / Manage subscriptions + Refunds

    func showManageSubscriptions() async {
        guard let scene = currentWindowScene() else { return }
        if #available(iOS 15.0, *) {
            do {
                try await AppStore.showManageSubscriptions(in: scene)
            } catch {
                purchaseStatus = .failed(error)
            }
        }
    }

    /// Requests a refund for the latest transaction of a product (Apple decides approval).
    func requestRefund(for productID: String) async {
        guard let scene = currentWindowScene() else { return }
        do {
            // latest(for:) returns VerificationResult<Transaction>
            if let latest = try await Transaction.latest(for: productID) {
                let transaction = try verifyPurchase(latest)

                if #available(iOS 15.0, *) {
                    _ = try await Transaction.beginRefundRequest(for: transaction.id, in: scene)
                }
            } else {
                purchaseStatus = .failed(StoreKitError.unknownError)
            }
        } catch {
            purchaseStatus = .failed(error)
        }
    }

    // MARK: - Verification + transaction updates

    func verifyPurchase<T>(_ verifcationResult: VerificationResult<T>) throws -> T {
        switch verifcationResult {
        case .unverified(_, let error):
            throw error
        case .verified(let result):
            return result
        }
    }

    private func transactionStatusStream() -> Task<Void, Error> {
        Task.detached { [weak self] in
            guard let self else { return }

            for await result in Transaction.updates {
                do {
                    let transaction = try await self.verifyPurchase(result)

                    // If a pending transaction resolves via updates, clear pending UI state
                    await MainActor.run {
                        self.pendingProductIDs.remove(transaction.productID)
                    }

                    // If a consumable resolves here (rare but possible), ensure we store it
                    if transaction.productType == .consumable {
                        await MainActor.run {
                            self.addConsumable(productID: transaction.productID, amount: 1)
                        }
                    }

                    await self.retrievePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction update verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Helpers

    private func sortByPrice(_ products: [Product]) -> [Product] {
        products.sorted(by: { $0.price < $1.price })
    }

    private func currentWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
    }
}
