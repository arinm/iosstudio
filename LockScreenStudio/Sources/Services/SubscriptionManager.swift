import StoreKit
import SwiftUI

/// Manages Pro subscription state using StoreKit 2.
/// Handles purchasing, restoring, and entitlement verification.
///
/// Product IDs (configure in App Store Connect):
/// - com.lockscreenstudio.pro.monthly
/// - com.lockscreenstudio.pro.yearly
@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: - Product IDs

    static let monthlyProductID = "com.lockscreenstudio.pro.monthly"
    static let yearlyProductID = "com.lockscreenstudio.pro.yearly"
    static let lifetimeProductID = "com.lockscreenstudio.pro.lifetime"
    static let allProductIDs: Set<String> = [monthlyProductID, yearlyProductID, lifetimeProductID]

    // MARK: - Published State

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    /// True if the user has an active Pro subscription.
    /// In DEBUG builds, set "debug_force_pro" in UserDefaults to override.
    var isPro: Bool {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "debug_force_pro") {
            return true
        }
        #endif
        return !purchasedProductIDs.isEmpty
    }

    /// The currently active subscription product, if any.
    var activeSubscription: Product? {
        products.first { purchasedProductIDs.contains($0.id) }
    }

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyProductID }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == Self.lifetimeProductID }
    }

    // MARK: - Transaction Listener

    private var transactionListener: Task<Void, Error>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            products = try await Product.products(for: Self.allProductIDs)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Unable to load subscription options."
        }

        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
            return true

        case .userCancelled:
            return false

        case .pending:
            errorMessage = "Purchase is pending approval."
            return false

        @unknown default:
            errorMessage = "An unexpected error occurred."
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // Sync with App Store
        try? await AppStore.sync()
        await updatePurchasedProducts()

        if purchasedProductIDs.isEmpty {
            errorMessage = "No active subscriptions found."
        }
    }

    // MARK: - Entitlement Check

    /// Updates the set of purchased product IDs by checking current entitlements.
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            }
        }

        purchasedProductIDs = purchased
    }

    // MARK: - Feature Gating

    /// Check if a specific feature is available (free or user has Pro).
    func hasAccess(to feature: ProFeature) -> Bool {
        if feature.isFree { return true }
        return isPro
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? self?.checkVerified(result) {
                    await transaction.finish()
                    await self?.updatePurchasedProducts()
                }
            }
        }
    }

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}

// MARK: - Feature Gating Model

enum ProFeature {
    case template(isPro: Bool)
    case unlimitedExports
    case premiumTheme
    case premiumFont
    case fullShortcutsIntents
    case advancedExportPresets
    case panelType(PanelType)

    var isFree: Bool {
        switch self {
        case .template(let isPro): return !isPro
        case .panelType(let type): return !type.isPro
        case .unlimitedExports, .premiumTheme, .premiumFont,
             .fullShortcutsIntents, .advancedExportPresets:
            return false
        }
    }
}

// MARK: - Export Limit Tracking

extension SubscriptionManager {
    private static let exportCountKey = "daily_export_count"
    private static let exportDateKey = "daily_export_date"
    static let freeExportLimit = 3

    var remainingFreeExports: Int {
        guard !isPro else { return .max }
        return max(0, Self.freeExportLimit - todayExportCount)
    }

    var canExport: Bool {
        isPro || todayExportCount < Self.freeExportLimit
    }

    private var todayExportCount: Int {
        let defaults = UserDefaults.standard
        let savedDate = defaults.string(forKey: Self.exportDateKey) ?? ""
        let today = Self.todayString

        if savedDate != today {
            return 0
        }
        return defaults.integer(forKey: Self.exportCountKey)
    }

    func recordExport() {
        guard !isPro else { return }

        let defaults = UserDefaults.standard
        let today = Self.todayString
        let savedDate = defaults.string(forKey: Self.exportDateKey) ?? ""

        if savedDate != today {
            defaults.set(today, forKey: Self.exportDateKey)
            defaults.set(1, forKey: Self.exportCountKey)
        } else {
            let current = defaults.integer(forKey: Self.exportCountKey)
            defaults.set(current + 1, forKey: Self.exportCountKey)
        }
    }

    private static var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
