# 🛒 StoreKit 2 Architecture Demo  
### SwiftUI • MVVM • StoreKit 2 • Async/Await

A **production-style demonstration** of Apple’s **StoreKit 2** APIs built with **SwiftUI** and a clean **MVVM architecture**.  
This project showcases how to correctly implement **in-app purchases, subscriptions, consumables, transaction verification, pending states, and local inventory** in a scalable and maintainable way.

> This is **not** a minimal tutorial — it is intentionally designed to mirror **real-world StoreKit implementations**.

---

## ✨ Features

- ✅ StoreKit 2 (async/await)
- ✅ Non-Consumable purchases
- ✅ Consumables with **local inventory tracking**
- ✅ Non-Renewable subscriptions (custom expiration logic)
- ✅ Auto-Renewable subscriptions
- ✅ Pending purchase states (Ask to Buy)
- ✅ Promo code redemption (Offer Code sheet)
- ✅ Restore purchases
- ✅ Refund requests & subscription management
- ✅ Clean MVVM separation
- ✅ Transaction verification & background updates
- ✅ SwiftUI-first UI layer

---

## 🧠 Key Concepts Demonstrated

This project focuses on **correct StoreKit mental models**, not shortcuts:

- **Consumables ≠ Entitlements**
- **Transactions can complete later**
- **Every transaction must be verified**
- **UI must never call StoreKit directly**
- **State must persist across app restarts**
- **Pending purchases must be visible to users**

---

## 🧱 Architecture Overview

The app follows a **three-layer MVVM architecture**:

SwiftUI Views
↓
StoreViewModel
↓
StoreDataService (StoreKit 2)

yaml
Copy code

---

## 🖼 View Layer (SwiftUI)

**Responsibility: UI only**

- Renders state provided by the ViewModel
- Displays products, prices, purchase status, and errors
- Shows loading / pending / success states
- Triggers user intent (buy, restore, redeem)

**Does NOT:**
- Talk to StoreKit
- Verify transactions
- Persist data

---

## 🧠 ViewModel Layer (`StoreViewModel`)

**Responsibility: UI-ready state + user intents**

The ViewModel acts as the **bridge** between UI and StoreKit logic.

### Exposes state such as:
- `nonConsumables`
- `consumables`
- `autoRenewables`
- `pendingProductIDs`
- `consumableBalances`
- `purchaseStatus`

### Exposes user intents:
- `purchase(product:)`
- `restorePurchases`
- `presentPromoCodeRedemption()`
- `showManageSubscriptions()`
- `requestRefund(productID:)`

The ViewModel:
- Translates StoreKit events into UI-friendly state
- Handles alerts and error messaging
- Never talks to StoreKit directly

---

## 🛠 Service Layer (`StoreDataService`)

**Responsibility: Single source of truth for StoreKit**

This layer encapsulates **all StoreKit 2 logic** and is marked `@MainActor` to guarantee safe UI updates.

### Handles:
- Product loading (`Product.products`)
- Purchase flow (`product.purchase()`)
- Transaction verification
- Finishing transactions
- Listening to `Transaction.updates`
- Tracking pending purchases
- Persisting consumable inventory
- Subscription status & refunds

---

## 🧾 Purchase Types Explained

### 🔹 Non-Consumables
- One-time purchase
- Stored in entitlements
- UI shows a **green checkmark** after purchase

---

### 🔹 Consumables
- Can be purchased multiple times
- **Never appear in entitlements**
- Stored locally as inventory (UserDefaults / AppStorage)
- UI reflects **balance**, not ownership

> Consumables are **inventory**, not entitlements.

---

### 🔹 Non-Renewables
- Time-limited access
- Custom expiration logic (1 year)
- Must be manually validated against purchase date

---

### 🔹 Auto-Renewable Subscriptions
- Managed by the App Store
- Status derived from subscription group state
- Cancellation handled via system UI

---

## ⏳ Pending Purchases

Some purchases require approval (e.g. **Ask to Buy**).

This app:
- Tracks pending purchases by product ID
- Disables purchase buttons while pending
- Shows loading indicators
- Resolves state via `Transaction.updates`

---

## 🎟 Promo Code Redemption

Promo codes are redeemed using Apple’s **system UI**:

```swift
AppStore.presentOfferCodeRedeemSheet(in: scene)
✔ Secure
✔ App Store compliant
✔ No custom input UI required

🔁 Restore Purchases
Handled using:

swift
Copy code
AppStore.sync()
This:

Re-syncs entitlements

Restores purchases on new devices

Updates UI state automatically

🔐 Transaction Verification
Every transaction is verified using:

swift
Copy code
VerificationResult<T>
Unverified transactions are never trusted.

This ensures:

Security

App Store compliance

Protection against tampering

🧵 Why @MainActor Is Used
Both StoreDataService and StoreViewModel are @MainActor isolated to:

Guarantee UI-safe updates

Avoid race conditions

Simplify async/await flows

Remove unnecessary dispatching

🚀 Getting Started
Open the project in Xcode

Enable In-App Purchase capability

Attach Store.storekit to the Run scheme

Run on Simulator or Device

Use StoreKit Testing or Sandbox accounts

📌 Why This Architecture Scales
This architecture makes it easy to:

Add new product types

Change UI without touching StoreKit logic

Handle StoreKit edge cases cleanly

Debug purchase issues confidently

Build production-ready purchase flows

🎤 Presentation / Interview Ready
If you can explain this codebase, you can explain:

Modern StoreKit 2

Async/await architecture

Transaction verification

Consumable vs entitlement logic

Real-world iOS monetization patterns

📄 License
This project is provided for educational and demonstration purposes.

Built with ❤️ using SwiftUI, StoreKit 2, and MVVM

yaml
Copy code

---

If you want next:
- a **shorter “interview version”** of the README
- an **architecture diagram (ASCII or image)**
- or **inline documentation comments** for teaching  

just tell me 👍
