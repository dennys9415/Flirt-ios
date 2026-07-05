import Foundation
import StoreKit

/// StoreKit 2 manager. Locally, products come from Flirt.storekit (Xcode's
/// StoreKit Testing) — no App Store Connect needed. After a purchase the
/// backend is notified (`POST /subscriptions/verify`) and upgrades the plan.
@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    static let productIds = [
        "com.singularitybox.flirt.pro.monthly",
        "com.singularitybox.flirt.premium.monthly",
    ]

    @Published var products: [Product] = []
    @Published var purchasedProductIds: Set<String> = []
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        // Handle renewals/revocations delivered outside a purchase flow
        updatesTask = Task {
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await self.handle(transaction: transaction)
                    await transaction.finish()
                }
            }
        }
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: Self.productIds)
                .sorted { $0.price < $1.price }
            await refreshEntitlements()
        } catch {
            lastError = "Couldn't load plans: \(error.localizedDescription)"
        }
    }

    /** Returns true when the purchase completed (not pending/cancelled). */
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(.verified(let transaction)):
                await handle(transaction: transaction)
                await transaction.finish()
                return true
            case .success(.unverified):
                lastError = "Purchase could not be verified"
                return false
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func refreshEntitlements() async {
        var owned: Set<String> = []
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement {
                owned.insert(transaction.productID)
            }
        }
        purchasedProductIds = owned
    }

    private func handle(transaction: Transaction) async {
        purchasedProductIds.insert(transaction.productID)
        do {
            _ = try await APIClient.shared.verifySubscription(
                transactionId: String(transaction.originalID),
                productId: transaction.productID,
                expiresAt: transaction.expirationDate
            )
        } catch {
            // Backend unreachable — entitlement still works locally;
            // next app launch retries via Transaction.updates
            lastError = error.localizedDescription
        }
    }
}
