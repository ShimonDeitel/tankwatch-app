import Foundation
import StoreKit

/// Single monthly auto-renewable Pro subscription.
enum ProductID {
    static let proMonthly = "com.shimondeitel.tankwatch.pro.monthly"
}

/// Live-derived Pro entitlement state, mirroring the pattern used across sibling apps.
/// `isPro` is always derived from `Transaction.currentEntitlements` — never cached truth.
/// DEBUG-only overrides let development/testing force a state without real StoreKit transactions:
///   - TANKWATCH_FORCE_PRO=1   -> isPro always true
///   - TANKWATCH_NO_SK=1       -> skip StoreKit entirely (e.g. previews/unit tests), isPro false
@MainActor
final class EntitlementsStore: ObservableObject {
    @Published private(set) var isPro: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoadingProducts: Bool = false
    @Published var lastErrorMessage: String?

    private var updatesTask: Task<Void, Never>?

    static let shared = EntitlementsStore()

    private init() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["TANKWATCH_FORCE_PRO"] == "1" {
            isPro = true
        }
        if ProcessInfo.processInfo.environment["TANKWATCH_NO_SK"] == "1" {
            return
        }
        #endif
        updatesTask = Task { [weak self] in
            await self?.listenForTransactionUpdates()
        }
        Task { [weak self] in
            await self?.refresh()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func refresh() async {
        #if DEBUG
        if ProcessInfo.processInfo.environment["TANKWATCH_FORCE_PRO"] == "1" {
            isPro = true
            return
        }
        if ProcessInfo.processInfo.environment["TANKWATCH_NO_SK"] == "1" {
            return
        }
        #endif
        await loadProducts()
        await refreshEntitlements()
    }

    private func loadProducts() async {
        guard products.isEmpty else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: [ProductID.proMonthly])
        } catch {
            lastErrorMessage = "Couldn't load Pro subscription: \(error.localizedDescription)"
        }
    }

    private func refreshEntitlements() async {
        var proActive = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == ProductID.proMonthly, transaction.revocationDate == nil {
                proActive = true
            }
        }
        isPro = proActive
    }

    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    func purchasePro() async {
        guard let product = products.first(where: { $0.id == ProductID.proMonthly }) else {
            await loadProducts()
            return
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastErrorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }
}
