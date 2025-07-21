//
//  AdManager.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//  Updated 7/21/2025 by @jrftw
//
//  Google Mobile Ads integration for banner advertisements
//  Provides ad loading, display, and premium user detection
//  Excluded from visionOS builds due to Google Mobile Ads compatibility issues
//

import Foundation
import SwiftUI
#if !os(visionOS)
import GoogleMobileAds

// MARK: - Ad Manager
/// Manages Google Mobile Ads integration for banner advertisements
/// Handles ad loading, display, and premium user detection
/// Excluded from visionOS builds due to compatibility issues
/// Uses @MainActor for UI thread safety and ObservableObject for SwiftUI integration
@MainActor
class AdManager: NSObject, ObservableObject, BannerViewDelegate {
    /// Shared singleton instance for app-wide ad management
    static let shared = AdManager()
    
    /// Indicates whether banner ad has been successfully loaded
    @Published var isAdLoaded = false
    
    /// Indicates whether ad is currently being displayed
    @Published var isShowingAd = false
    
    /// Error message if ad loading fails
    @Published var adError: String?
    
    // MARK: - Ad Configuration
    /// Production Google Mobile Ads application ID
    private let appID = "ca-app-pub-6815311336585204~2405052859"
    
    /// Production banner ad unit ID
    private let bannerAdUnitID = "ca-app-pub-6815311336585204/2974848746"
    
    /// Test banner ad unit ID for development
    private let testBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    
    /// Real banner view instance for displaying ads
    private var bannerView: BannerView?
    
    // MARK: - Initialization
    /// Private initializer that sets up Google Mobile Ads
    /// Ensures proper initialization of ad framework
    private override init() {
        super.init()
        setupGoogleMobileAds()
    }
    
    /// Sets up Google Mobile Ads framework
    /// Initializes the MobileAds shared instance
    private func setupGoogleMobileAds() {
        // Initialize Google Mobile Ads
        MobileAds.shared.start { status in
            print("Google Mobile Ads initialization status: \(status)")
        }
    }
    
    // MARK: - Ad Loading
    
    /// Loads banner advertisement
    /// Creates banner view if needed and requests ad from Google
    func loadBannerAd() {
        isAdLoaded = false
        adError = nil
        
        // Create banner view if it doesn't exist
        if bannerView == nil {
            bannerView = BannerView(adSize: AdSizeBanner)
            bannerView?.delegate = self
            bannerView?.adUnitID = isDebugMode() ? testBannerAdUnitID : bannerAdUnitID
        }
        
        // Load the ad
        let request = Request()
        bannerView?.load(request)
    }
    
    // MARK: - General Ad Methods (for AppViewModel compatibility)
    
    /// General ad loading method for compatibility with AppViewModel
    /// Delegates to banner ad loading
    func loadAd() {
        loadBannerAd()
    }
    
    /// Shows advertisement with completion handler
    /// Simulates ad display for non-banner ad types
    func showAd(completion: @escaping () -> Void = {}) {
        guard isAdLoaded && !isShowingAd else { 
            completion()
            return 
        }
        isShowingAd = true
        
        // Mock ad display - simulate ad completion after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isShowingAd = false
            completion()
        }
    }
    
    /// Determines if app is running in debug mode
    /// Used to switch between test and production ad units
    private func isDebugMode() -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Ad Display
    
    /// Returns the banner view for SwiftUI integration
    /// Used by BannerViewRepresentable to display ads
    func getBannerView() -> BannerView? {
        return bannerView
    }
    
    /// Shows banner advertisement
    /// Updates display state when ad is shown
    func showBannerAd() {
        guard isAdLoaded && !isShowingAd else { return }
        isShowingAd = true
    }
    
    // MARK: - Ad Status
    
    /// Checks if banner ad can be displayed
    /// Returns true if ad is loaded and not currently showing
    func canShowBannerAd() -> Bool {
        return isAdLoaded && !isShowingAd
    }
    
    /// Checks if current user has premium subscription
    /// Premium users should not see advertisements
    func isPremiumUser() -> Bool {
        return checkPremiumStatus()
    }
    
    /// Reference to data manager for premium status checking
    private var dataManager: Any?
    
    /// Sets the data manager for premium status checking
    /// Supports both HybridDataManager and VisionOSDataManager
    func setDataManager(_ manager: Any) {
        self.dataManager = manager
    }
    
    /// Checks premium status from data manager
    /// Supports multiple data manager types for cross-platform compatibility
    private func checkPremiumStatus() -> Bool {
        if let hybridManager = dataManager as? HybridDataManager {
            return hybridManager.isPremium
        } else if let visionOSManager = dataManager as? VisionOSDataManager {
            return visionOSManager.isPremium
        }
        return false
    }
    
}

// MARK: - Google Mobile Ads Delegate
/// Extension implementing Google Mobile Ads delegate methods
/// Handles ad loading success, failure, and display events
extension AdManager {
    /// Called when banner ad is successfully loaded
    /// Updates loading state and clears any previous errors
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        isAdLoaded = true
        adError = nil
        print("Banner ad loaded successfully")
    }
    
    /// Called when banner ad fails to load
    /// Updates loading state and stores error message
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        isAdLoaded = false
        adError = error.localizedDescription
        print("Banner ad failed to load: \(error.localizedDescription)")
    }
    
    /// Called when banner ad will present full-screen content
    /// Updates display state to indicate ad is being shown
    func bannerViewWillPresentScreen(_ bannerView: BannerView) {
        isShowingAd = true
        print("Banner ad will present screen")
    }
    
    /// Called when banner ad dismisses full-screen content
    /// Updates display state to indicate ad is no longer showing
    func bannerViewDidDismissScreen(_ bannerView: BannerView) {
        isShowingAd = false
        print("Banner ad did dismiss screen")
    }
}
#endif

// MARK: - Ad View Components
/// SwiftUI components for displaying banner advertisements
/// Excluded from visionOS builds due to Google Mobile Ads compatibility

#if !os(visionOS)
/// SwiftUI view for displaying banner advertisements
/// Automatically hides ads for premium users
struct AdBannerView: View {
    /// Shared ad manager instance
    @ObservedObject var adManager = AdManager.shared
    
    var body: some View {
        // Don't show ads for premium users
        if adManager.isPremiumUser() {
            EmptyView()
        } else if adManager.canShowBannerAd() {
            BannerViewRepresentable(adManager: adManager)
                .frame(height: 50)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        } else {
            EmptyView()
        }
    }
}

/// UIViewRepresentable wrapper for Google Mobile Ads BannerView
/// Integrates UIKit banner view into SwiftUI view hierarchy
struct BannerViewRepresentable: UIViewRepresentable {
    /// Ad manager instance for accessing banner view
    let adManager: AdManager
    
    /// Creates UIKit view container for banner advertisement
    /// Sets up constraints and adds banner view to container
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        // Get the real banner view from AdManager
        if let bannerView = adManager.getBannerView() {
            containerView.addSubview(bannerView)
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                bannerView.topAnchor.constraint(equalTo: containerView.topAnchor),
                bannerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                bannerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                bannerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
        
        return containerView
    }
    
    /// Updates UIKit view when SwiftUI state changes
    /// Currently no-op as banner view is self-contained
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
}
#endif 