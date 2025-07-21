import Foundation
import SwiftUI

@MainActor
class AdManager: ObservableObject {
    static let shared = AdManager()
    
    @Published var isAdLoaded = false
    @Published var isShowingAd = false
    @Published var adError: String?
    
    private var adUnitID = "ca-app-pub-3940256099942544/2934735716" // Test ad unit ID
    
    private init() {}
    
    // MARK: - Ad Loading
    
    func loadAd() {
        isAdLoaded = false
        adError = nil
        
        // Simulate ad loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isAdLoaded = true
        }
    }
    
    // MARK: - Ad Display
    
    func showAd(completion: @escaping () -> Void = {}) {
        guard isAdLoaded && !isShowingAd else {
            completion()
            return
        }
        
        isShowingAd = true
        
        // Simulate ad display
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.isShowingAd = false
            self.isAdLoaded = false
            completion()
        }
    }
    
    // MARK: - Ad Status
    
    func canShowAd() -> Bool {
        return isAdLoaded && !isShowingAd
    }
    
    // MARK: - Ad Types
    
    enum AdType {
        case banner
        case interstitial
        case rewarded
        
        var unitID: String {
            switch self {
            case .banner:
                return "ca-app-pub-3940256099942544/2934735716" // Test banner
            case .interstitial:
                return "ca-app-pub-3940256099942544/4411468910" // Test interstitial
            case .rewarded:
                return "ca-app-pub-3940256099942544/1712485313" // Test rewarded
            }
        }
    }
}

// MARK: - Ad View
struct AdBannerView: View {
    @ObservedObject var adManager = AdManager.shared
    
    var body: some View {
        if adManager.isAdLoaded {
            VStack {
                HStack {
                    Image(systemName: "megaphone.fill")
                        .foregroundStyle(.orange)
                    Text("Advertisement")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        } else {
            EmptyView()
        }
    }
} 