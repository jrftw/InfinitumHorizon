import Foundation
import SwiftUI
import Combine

@MainActor
class AppViewModel: ObservableObject {
    @Published var currentScreen: Int = 1
    @Published var showPremiumUpgrade = false
    @Published var showPromoCode = false
    @Published var promoCodeInput = ""
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isLoading = false
    
    private let dataManager: HybridDataManager
    let multipeerManager = MultipeerManager.shared
    let storeKitManager = StoreKitManager.shared
    let permissionManager = PermissionManager.shared
    let adManager = AdManager.shared
    let crossDeviceControlManager = CrossDeviceControlManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(dataManager: HybridDataManager) {
        self.dataManager = dataManager
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind premium status
        dataManager.$isPremium
            .sink { [weak self] isPremium in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Bind unlocked screens
        dataManager.$unlockedScreens
            .sink { [weak self] unlockedScreens in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Navigation
    
    func navigateToScreen(_ screenNumber: Int) {
        guard (dataManager as HybridDataManager).canAccessScreen(screenNumber) else {
            showPremiumUpgrade = true
            return
        }
        
        currentScreen = screenNumber
    }
    
    func canAccessScreen(_ screenNumber: Int) -> Bool {
        return (dataManager as HybridDataManager).canAccessScreen(screenNumber)
    }
    
    var dataManagerInstance: HybridDataManager {
        return dataManager
    }
    
    // MARK: - Premium Features
    
    func upgradeToPremium(plan: String) {
        isLoading = true
        
        let productID = plan == "monthly" ? "com.infinitumhorizon.premium.monthly" : "com.infinitumhorizon.premium.yearly"
        
        guard let product = storeKitManager.getProduct(for: productID) else {
            showAlert(message: "Product not available")
            isLoading = false
            return
        }
        
        Task(priority: .userInitiated) { @MainActor in
            do {
                if try await storeKitManager.purchase(product) != nil {
                    (dataManager as HybridDataManager).purchasePremium()
                    showAlert(message: "Premium \(plan) plan activated successfully! 🎉")
                } else {
                    showAlert(message: "Purchase was cancelled")
                }
            } catch {
                showAlert(message: "Purchase failed: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    func redeemPromoCode(_ code: String, completion: @escaping (Bool) -> Void) {
        guard !code.isEmpty else {
            showAlert(message: "Please enter a promo code")
            completion(false)
            return
        }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let success = (self.dataManager as HybridDataManager).unlockPremiumWithPromoCode(code)
            
            if success {
                self.showAlert(message: "Promo code redeemed successfully! 🎉")
                completion(true)
            } else {
                self.showAlert(message: "Invalid promo code. Please try again.")
                completion(false)
            }
            
            self.isLoading = false
        }
    }
    
    func unlockWithPromoCode() {
        guard !promoCodeInput.isEmpty else {
            showAlert(message: "Please enter a promo code")
            return
        }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let success = (self.dataManager as HybridDataManager).unlockPremiumWithPromoCode(self.promoCodeInput)
            
            if success {
                self.showAlert(message: "Premium unlocked successfully! 🎉")
                self.promoCodeInput = ""
                self.showPromoCode = false
            } else {
                self.showAlert(message: "Invalid promo code. Please try again.")
            }
            
            self.isLoading = false
        }
    }
    
    func purchasePremium() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            (self.dataManager as HybridDataManager).purchasePremium()
            self.showAlert(message: "Premium purchased successfully! 🎉")
            self.showPremiumUpgrade = false
            self.isLoading = false
        }
    }
    
    // MARK: - Multipeer Connectivity
    
    func startHosting() {
        multipeerManager.startHosting()
    }
    
    func startBrowsing() {
        multipeerManager.startBrowsing()
    }
    
    func stopConnection() {
        multipeerManager.disconnect()
    }
    
    func sendMessage(_ message: String) {
        multipeerManager.sendMessage(message)
    }
    
    // MARK: - Session Management
    
    func createSession(name: String) {
        guard let session = (dataManager as HybridDataManager).createSession(name: name) else {
            showAlert(message: "Failed to create session")
            return
        }
        
        showAlert(message: "Session created: \(session.name)")
    }
    
    func joinSession(_ sessionId: String) {
        guard (dataManager as HybridDataManager).joinSession(sessionId) else {
            showAlert(message: "Failed to join session")
            return
        }
        
        showAlert(message: "Joined session successfully")
    }
    
    // MARK: - Utility
    
    func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
    
    // MARK: - Ad Management
    
    func showAd() {
        guard let user = dataManager.currentUser,
              user.adsEnabled && !user.isPremium else { return }
        
        adManager.showAd {
            self.showAlert(message: "Ad completed")
        }
    }
    
    func loadAd() {
        adManager.loadAd()
    }
    
    // MARK: - Platform-specific features
    
    func getPlatformSpecificFeatures() -> [String] {
        #if os(visionOS)
        return ["Spatial Computing", "Hand Tracking", "Eye Tracking", "Immersive Experiences", "Cross-Device Control"]
        #elseif os(iOS)
        return ["Touch Interface", "Haptic Feedback", "Camera Integration", "Face ID", "Dynamic Island", "Cross-Device Control"]
        #elseif os(macOS)
        return ["Keyboard Shortcuts", "Window Management", "Desktop Integration", "Touch Bar Support", "Cross-Device Control"]
        #elseif os(watchOS)
        return ["Health Integration", "Quick Actions", "Digital Crown", "Always-On Display", "Cross-Device Control"]
        #else
        return ["Cross-platform Sync", "Cloud Storage", "Cross-Device Control"]
        #endif
    }
    
    // MARK: - Cross-Device Control
    
    func startCrossDeviceControl() {
        crossDeviceControlManager.startHosting()
    }
    
    func stopCrossDeviceControl() {
        crossDeviceControlManager.disconnect()
    }
    
    func sendHapticToWatch() {
        crossDeviceControlManager.sendHapticToWatch(.notification)
    }
    
    func launchAppOnDevice(_ deviceId: String, appURL: URL) {
        crossDeviceControlManager.launchAppOnDevice(deviceId, appURL: appURL) { success in
            if success {
                self.showAlert(message: "App launched successfully on \(deviceId)")
            } else {
                self.showAlert(message: "Failed to launch app on \(deviceId)")
            }
        }
    }
    
    func executeScriptOnMac(_ script: String) {
        crossDeviceControlManager.executeAppleScriptOnMac(script) { success in
            if success {
                self.showAlert(message: "Script executed successfully")
            } else {
                self.showAlert(message: "Failed to execute script")
            }
        }
    }
    
    func changeVisionProLayout(_ layout: VisionProLayout) {
        crossDeviceControlManager.changeVisionProLayout(layout) { success in
            if success {
                self.showAlert(message: "Layout changed to \(layout.rawValue)")
            } else {
                self.showAlert(message: "Failed to change layout")
            }
        }
    }
} 