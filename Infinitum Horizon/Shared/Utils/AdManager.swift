import Foundation
import SwiftUI
#if !os(visionOS)
import GoogleMobileAds

@MainActor
class AdManager: NSObject, ObservableObject, BannerViewDelegate {
    static let shared = AdManager()
    
    @Published var isAdLoaded = false
    @Published var isShowingAd = false
    @Published var adError: String?
    
    // Production Ad Unit IDs
    private let appID = "ca-app-pub-6815311336585204~2405052859"
    private let bannerAdUnitID = "ca-app-pub-6815311336585204/2974848746"
    private let testBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    
    // Real banner view
    private var bannerView: BannerView?
    
    private override init() {
        super.init()
        setupGoogleMobileAds()
    }
    
    private func setupGoogleMobileAds() {
        // Initialize Google Mobile Ads
        MobileAds.shared.start { status in
            print("Google Mobile Ads initialization status: \(status)")
        }
    }
    
    // MARK: - Ad Loading
    
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
    
    func loadAd() {
        loadBannerAd()
    }
    
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
    
    private func isDebugMode() -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Ad Display
    
    func getBannerView() -> BannerView? {
        return bannerView
    }
    
    func showBannerAd() {
        guard isAdLoaded && !isShowingAd else { return }
        isShowingAd = true
    }
    
    // MARK: - Ad Status
    
    func canShowBannerAd() -> Bool {
        return isAdLoaded && !isShowingAd
    }
    
    func isPremiumUser() -> Bool {
        return checkPremiumStatus()
    }
    
    private var dataManager: Any?
    
    func setDataManager(_ manager: Any) {
        self.dataManager = manager
    }
    
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
extension AdManager {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        isAdLoaded = true
        adError = nil
        print("Banner ad loaded successfully")
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        isAdLoaded = false
        adError = error.localizedDescription
        print("Banner ad failed to load: \(error.localizedDescription)")
    }
    
    func bannerViewWillPresentScreen(_ bannerView: BannerView) {
        isShowingAd = true
        print("Banner ad will present screen")
    }
    
    func bannerViewDidDismissScreen(_ bannerView: BannerView) {
        isShowingAd = false
        print("Banner ad did dismiss screen")
    }
}
#endif

// MARK: - Ad View
#if !os(visionOS)
struct AdBannerView: View {
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

struct BannerViewRepresentable: UIViewRepresentable {
    let adManager: AdManager
    
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
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
}
#endif 