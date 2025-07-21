import Foundation
import StoreKit

@MainActor
class StoreKitManager: NSObject, ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var productIDs = [
        "com.infinitumhorizon.premium.monthly",
        "com.infinitumhorizon.premium.yearly"
    ]
    
    private var updates: Task<Void, Error>? = nil
    
    private override init() {
        super.init()
        updates = observeTransactionUpdates()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            products = try await Product.products(for: productIDs)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            #if DEBUG
            print("Failed to load products: \(error)")
            #endif
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        errorMessage = nil
        
        #if os(visionOS)
        // StoreKit purchases are not available in visionOS
        isLoading = false
        errorMessage = "In-app purchases are not available in visionOS"
        throw StoreError.notAvailable
        #else
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedProducts()
                await transaction.finish()
                isLoading = false
                return transaction
                
            case .userCancelled:
                isLoading = false
                return nil
                
            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval"
                return nil
                
            @unknown default:
                isLoading = false
                errorMessage = "Unknown purchase result"
                return nil
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
        #endif
    }
    
    // MARK: - Transaction Updates
    
    private func observeTransactionUpdates() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    #if DEBUG
                    print("Transaction failed verification: \(error)")
                    #endif
                }
            }
        }
    }
    
    // MARK: - Verification
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Purchased Products
    
    func updatePurchasedProducts() async {
        var purchasedProductIDs = Set<String>()
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedProductIDs.insert(transaction.productID)
            } catch {
                #if DEBUG
                print("Transaction failed verification: \(error)")
                #endif
            }
        }
        
        self.purchasedProductIDs = purchasedProductIDs
    }
    
    // MARK: - Helper Methods
    
    func isPurchased(_ productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }
    
    func getProduct(for productID: String) -> Product? {
        return products.first { $0.id == productID }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            #if DEBUG
            print("Failed to restore purchases: \(error)")
            #endif
        }
    }
}

// MARK: - Store Errors
enum StoreError: LocalizedError {
    case failedVerification
    case notAvailable
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .notAvailable:
            return "In-app purchases are not available on this platform"
        }
    }
} 