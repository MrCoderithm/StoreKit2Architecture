StoreKit 2 Architecture Demo (SwiftUI + MVVM)

A production-style demonstration of StoreKit 2 implemented using SwiftUI and MVVM, showcasing how to handle in-app purchases, subscriptions, consumables, transaction verification, pending states, and local inventory in a clean and maintainable architecture.

This project is intentionally structured to mirror real-world StoreKit implementations, not just minimal examples.

✨ Features

✅ StoreKit 2 APIs (async/await)

✅ Non-Consumable purchases

✅ Consumable purchases with local inventory tracking

✅ Non-Renewable subscriptions with expiration logic

✅ Auto-Renewable subscriptions with status tracking

✅ Promo code redemption (Offer Code sheet)

✅ Restore purchases

✅ Pending purchase UI states

✅ Refund & subscription management (system UI)

✅ Clean MVVM separation

✅ SwiftUI-first UI layer

✅ Transaction verification & background updates

🧠 Core Concepts Demonstrated

This app focuses on correct mental models for StoreKit 2:

Entitlements ≠ Consumables

Transactions may complete later

Verification is mandatory

UI should never talk to StoreKit directly

State must survive app restarts

Pending purchases must be visible to users

🧱 Architecture Overview

This project follows a three-layer MVVM architecture:

SwiftUI Views
      ↓
StoreViewModel
      ↓
StoreDataService (StoreKit 2)

1️⃣ View Layer (SwiftUI)

Responsibility: UI only

Renders state provided by the ViewModel

Displays products, prices, purchase status, and errors

Shows loading / pending / success states

Never calls StoreKit APIs directly

Example responsibilities:

Show “Buy”, “Pending…”, or “Purchased”

Present Store view

Trigger user intents (buy, restore, redeem code)

2️⃣ ViewModel Layer (StoreViewModel)

Responsibility: UI-ready state + user intents

The ViewModel acts as the bridge between SwiftUI and StoreKit logic.

It:

Exposes observable properties for UI:

nonConsumables

consumables

subscriptions

pendingProductIDs

consumableBalances

Translates raw StoreKit events into UI-friendly state

Handles alerts and error messages

Forwards user actions to the service layer

The ViewModel does not:

Talk to StoreKit directly

Verify transactions

Persist inventory

3️⃣ Service Layer (StoreDataService)

Responsibility: Single source of truth for StoreKit

This layer encapsulates all StoreKit 2 logic and is marked @MainActor to guarantee safe UI updates.

It handles:

🔹 Product Loading
Product.products(for: productIDs)

🔹 Purchasing Flow
try await product.purchase()


Handles .success, .pending, .userCancelled

Verifies every transaction

Finishes transactions

Updates published state

🔹 Transaction Verification
VerificationResult<T>


Every transaction is cryptographically verified before being accepted.

🔹 Transaction Updates
for await update in Transaction.updates


Ensures:

Purchases completed later are handled

Pending states are resolved

Inventory is updated even if app restarts

🔹 Consumable Inventory (Important)

Consumables do not appear in entitlements.

This app:

Stores consumable balances locally using UserDefaults

Treats consumables as inventory, not ownership

Exposes balances to UI via published state

🔹 Subscription Management

Reads subscription group status

Opens Apple’s system subscription management UI

Requests refunds using StoreKit APIs

🧾 Purchase Types Explained
🔸 Non-Consumables

One-time purchase

Stored in entitlements

UI shows green checkmark after purchase

🔸 Consumables

Purchased multiple times

Never stored in entitlements

Balance tracked locally

UI reflects inventory count instead of “purchased”

🔸 Non-Renewables

Time-limited access

Custom expiration logic implemented (1 year)

Requires manual validation against purchase date

🔸 Auto-Renewables (Subscriptions)

Managed by App Store

Status determined by subscription group state

Cancelation handled via system UI

⏳ Pending Purchases

Some purchases require external approval (e.g., Ask to Buy).

This app:

Tracks pending purchases by product ID

Disables purchase buttons while pending

Shows loading indicators

Resolves pending states via Transaction.updates

🎟 Promo Codes

Promo codes are redeemed using Apple’s system UI:

AppStore.presentOfferCodeRedeemSheet(in: scene)


This ensures:

App Store compliance

Secure redemption

No custom code entry UI required

🔁 Restore Purchases

Handled via:

AppStore.sync()


Which:

Re-syncs entitlements

Rebuilds purchased product lists

Restores access on new devices

🧪 Why @MainActor Matters

StoreKit publishes state that drives UI.

By marking:

StoreDataService

StoreViewModel

as @MainActor, we guarantee:

UI updates happen on the main thread

No race conditions

Cleaner async code without DispatchQueue.main.async

🧼 Why This Architecture Scales

This architecture makes it easy to:

Add new product types

Change UI without touching StoreKit logic

Test business logic separately

Handle StoreKit edge cases cleanly

Reason about purchase state confidently

It also matches patterns used in production apps, not just tutorials.

🚀 Getting Started

Open the project in Xcode

Enable In-App Purchase capability

Attach Store.storekit to the Run scheme

Run on simulator or device

Use StoreKit testing or sandbox accounts

📌 Final Notes

This project is designed to be:

Educational

Interview-ready

Presentation-ready

Production-inspired

If you understand this codebase, you understand modern StoreKit 2 architecture.
