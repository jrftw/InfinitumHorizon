import SwiftUI
import RealityKit
import SwiftData
import Combine

struct VisionOSEntryView: View {
    @StateObject private var viewModel: VisionOSAppViewModel
    @StateObject private var versionManager = AppVersionManager.shared
    @State private var selectedTab = 0
    @State private var batteryLevel: Float = 0.0
    @State private var isCharging = false
    
    init(dataManager: HybridDataManager) {
        // Use VisionOSDataManager for visionOS
        let visionOSDataManager = VisionOSDataManager(modelContext: dataManager.getModelContext)
        self._viewModel = StateObject(wrappedValue: VisionOSAppViewModel(dataManager: visionOSDataManager))
    }
    
    // Alternative initializer for direct model context
    init(modelContext: ModelContext) {
        let visionOSDataManager = VisionOSDataManager(modelContext: modelContext)
        self._viewModel = StateObject(wrappedValue: VisionOSAppViewModel(dataManager: visionOSDataManager))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.clear
                .background(.ultraThinMaterial)
            
            VStack(spacing: 0) {
                // Status Bar
                StatusBarView(
                    batteryLevel: batteryLevel,
                    isCharging: isCharging,
                    versionManager: versionManager
                )
                
                // Main Content
                TabView(selection: $selectedTab) {
                    // Home Tab
                    NavigationView {
                        VisionHomeView(viewModel: viewModel)
                    }
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                    
                    // Screens Tab
                    NavigationView {
                        VisionScreensView(viewModel: viewModel)
                    }
                    .tabItem {
                        Image(systemName: "square.grid.2x2.fill")
                        Text("Screens")
                    }
                    .tag(1)
                    
                    // Connect Tab
                    NavigationView {
                        VisionConnectView(viewModel: viewModel)
                    }
                    .tabItem {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text("Connect")
                    }
                    .tag(2)
                    
                    // Settings Tab
                    NavigationView {
                        VisionSettingsView(viewModel: viewModel, versionManager: versionManager)
                    }
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(3)
                }
            }
        }
        .sheet(isPresented: $viewModel.showPremiumUpgrade) {
            VisionPremiumUpgradeView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showPromoCode) {
            VisionPromoCodeView(viewModel: viewModel)
        }
        .alert("Message", isPresented: $viewModel.showAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .onAppear {
            updateBatteryStatus()
            startBatteryMonitoring()
        }
    }
    
    private func updateBatteryStatus() {
        // In a real app, you would use UIDevice.current.batteryLevel
        // For now, we'll simulate battery level
        batteryLevel = Float.random(in: 0.2...1.0)
        isCharging = Bool.random()
    }
    
    private func startBatteryMonitoring() {
        // Set up timer to update battery status
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            updateBatteryStatus()
        }
    }
}

// MARK: - VisionOS App ViewModel (No Firebase)
@MainActor
class VisionOSAppViewModel: ObservableObject {
    @Published var currentScreen: Int = 1
    @Published var showPremiumUpgrade = false
    @Published var showPromoCode = false
    @Published var promoCodeInput = ""
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isLoading = false
    
    private let dataManager: Any
    let multipeerManager = MultipeerManager.shared
    let storeKitManager = StoreKitManager.shared
    let permissionManager = PermissionManager.shared
    let adManager = AdManager.shared
    let crossDeviceControlManager = CrossDeviceControlManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(dataManager: Any) {
        self.dataManager = dataManager
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind premium status and unlocked screens based on data manager type
        if let visionOSDataManager = dataManager as? VisionOSDataManager {
            visionOSDataManager.$isPremium
                .sink { [weak self] isPremium in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
            
            visionOSDataManager.$unlockedScreens
                .sink { [weak self] unlockedScreens in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        } else if let regularDataManager = dataManager as? DataManager {
            regularDataManager.$isPremium
                .sink { [weak self] isPremium in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
            
            regularDataManager.$unlockedScreens
                .sink { [weak self] unlockedScreens in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Navigation
    
    func navigateToScreen(_ screenNumber: Int) {
        guard canAccessScreen(screenNumber) else {
            showPremiumUpgrade = true
            return
        }
        
        currentScreen = screenNumber
    }
    
    func canAccessScreen(_ screenNumber: Int) -> Bool {
        if let visionOSDataManager = dataManager as? VisionOSDataManager {
            return visionOSDataManager.canAccessScreen(screenNumber)
        } else if let regularDataManager = dataManager as? DataManager {
            return regularDataManager.canAccessScreen(screenNumber)
        }
        return false
    }
    
    var dataManagerInstance: Any {
        return dataManager
    }
    
    // MARK: - Premium Features
    
    func unlockPremium() {
        if let visionOSDataManager = dataManager as? VisionOSDataManager {
            visionOSDataManager.purchasePremium()
        } else if let regularDataManager = dataManager as? DataManager {
            regularDataManager.purchasePremium()
        }
        showAlert = true
        alertMessage = "Premium features unlocked!"
    }
    
    func applyPromoCode(_ code: String) {
        let success: Bool
        if let visionOSDataManager = dataManager as? VisionOSDataManager {
            success = visionOSDataManager.applyPromoCode(code)
        } else if let regularDataManager = dataManager as? DataManager {
            success = regularDataManager.applyPromoCode(code)
        } else {
            success = false
        }
        
        if success {
            showAlert = true
            alertMessage = "Promo code applied successfully!"
            showPromoCode = false
        } else {
            showAlert = true
            alertMessage = "Invalid promo code"
        }
    }
}

// MARK: - Status Bar View
struct StatusBarView: View {
    let batteryLevel: Float
    let isCharging: Bool
    @ObservedObject var versionManager: AppVersionManager
    
    var body: some View {
        HStack {
            // Left side - App info
            HStack(spacing: 12) {
                Image(systemName: "infinity.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.linearGradient(
                        colors: [.orange, .red, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("Infinitum Horizon")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(versionManager.fullVersionString)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Right side - Status indicators
            HStack(spacing: 16) {
                // Battery indicator
                HStack(spacing: 4) {
                    Image(systemName: isCharging ? "battery.100.bolt" : "battery.100")
                        .font(.caption)
                        .foregroundStyle(isCharging ? .green : .primary)
                    
                    Text("\(Int(batteryLevel * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                // Time
                Text(Date().formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Vision Home View
struct VisionHomeView: View {
    @ObservedObject var viewModel: VisionOSAppViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "infinity.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.linearGradient(
                            colors: [.orange, .red, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("Infinitum Horizon")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Spatial Computing Experience")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Quick Actions
                VStack(spacing: 16) {
                    Text("Quick Actions")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        VisionQuickActionCard(
                            icon: "square.grid.2x2.fill",
                            title: "Screens",
                            subtitle: "Access your content",
                            color: .blue
                        ) {
                            viewModel.navigateToScreen(1)
                        }
                        
                        VisionQuickActionCard(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "Connect",
                            subtitle: "Device connectivity",
                            color: .green
                        ) {
                            viewModel.navigateToScreen(2)
                        }
                        
                        VisionQuickActionCard(
                            icon: "gear",
                            title: "Settings",
                            subtitle: "App configuration",
                            color: .orange
                        ) {
                            viewModel.navigateToScreen(3)
                        }
                        
                        VisionQuickActionCard(
                            icon: "crown.fill",
                            title: "Premium",
                            subtitle: "Upgrade features",
                            color: .purple
                        ) {
                            viewModel.showPremiumUpgrade = true
                        }
                    }
                }
                
                // User Info
                Group {
                    if let dataManager = viewModel.dataManagerInstance as? VisionOSDataManager, let user = dataManager.currentUser {
                        AccountInfoView(user: user)
                    } else if let dataManager = viewModel.dataManagerInstance as? DataManager, let user = dataManager.currentUser {
                        AccountInfoView(user: user)
                    }
                }
                
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
        }
        .background(.ultraThinMaterial)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Vision Quick Action Card
struct VisionQuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Account Info View
struct AccountInfoView: View {
    let user: User

    var body: some View {
        VStack(spacing: 16) {
            Text("Account")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.username)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(user.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(user.isPremium ? "Premium" : "Free")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(user.isPremium ? .green : .orange)

                    Text("\(user.unlockedScreens)/\(user.totalScreens) screens")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Vision Screens View
struct VisionScreensView: View {
    @ObservedObject var viewModel: VisionOSAppViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Available Screens")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                let totalScreens: Int = {
                    if let visionOSDataManager = viewModel.dataManagerInstance as? VisionOSDataManager {
                        return visionOSDataManager.currentUser?.totalScreens ?? 10
                    } else if let regularDataManager = viewModel.dataManagerInstance as? DataManager {
                        return regularDataManager.currentUser?.totalScreens ?? 10
                    } else {
                        return 10
                    }
                }()
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(1...totalScreens, id: \.self) { screenNumber in
                        let isPremium: Bool = {
                            if let visionOSDataManager = viewModel.dataManagerInstance as? VisionOSDataManager {
                                return visionOSDataManager.isPremium
                            } else if let regularDataManager = viewModel.dataManagerInstance as? DataManager {
                                return regularDataManager.isPremium
                            } else {
                                return false
                            }
                        }()
                        
                        ScreenCard(
                            screenNumber: screenNumber,
                            isUnlocked: viewModel.canAccessScreen(screenNumber),
                            isPremium: isPremium
                        ) {
                            viewModel.navigateToScreen(screenNumber)
                        }
                    }
                }
                
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
        }
        .background(.ultraThinMaterial)
        .navigationTitle("Screens")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Screen Card
struct ScreenCard: View {
    let screenNumber: Int
    let isUnlocked: Bool
    let isPremium: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: isUnlocked ? "\(screenNumber).circle.fill" : "lock.circle.fill")
                    .font(.title)
                    .foregroundStyle(isUnlocked ? .blue : .gray)
                
                Text("Screen \(screenNumber)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)
                
                if !isUnlocked {
                    Text("Premium")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isUnlocked)
    }
}

// MARK: - Vision Connect View
struct VisionConnectView: View {
    @ObservedObject var viewModel: VisionOSAppViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Device Connectivity")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Connection Status
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        
                        Text("Multipeer Connectivity")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Status:")
                        Spacer()
                        Text("Ready")
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Connection Actions
                VStack(spacing: 16) {
                    Button("Start Hosting") {
                        viewModel.multipeerManager.startHosting()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .fontWeight(.semibold)
                    
                    Button("Start Browsing") {
                        viewModel.multipeerManager.startBrowsing()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .fontWeight(.semibold)
                }
                
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
        }
        .background(.ultraThinMaterial)
        .navigationTitle("Connect")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Vision Settings View
struct VisionSettingsView: View {
    @ObservedObject var viewModel: VisionOSAppViewModel
    @ObservedObject var versionManager: AppVersionManager
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var showChangelog = false
    
    var body: some View {
        List {
            Section {
                let username: String = {
                    if let visionOSDataManager = viewModel.dataManagerInstance as? VisionOSDataManager {
                        return visionOSDataManager.currentUser?.username ?? "Unknown"
                    } else if let regularDataManager = viewModel.dataManagerInstance as? DataManager {
                        return regularDataManager.currentUser?.username ?? "Unknown"
                    } else {
                        return "Unknown"
                    }
                }()
                
                HStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text(username)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                let platform: String = {
                    if let visionOSDataManager = viewModel.dataManagerInstance as? VisionOSDataManager {
                        return visionOSDataManager.currentUser?.platform ?? "Unknown"
                    } else if let regularDataManager = viewModel.dataManagerInstance as? DataManager {
                        return regularDataManager.currentUser?.platform ?? "Unknown"
                    } else {
                        return "Unknown"
                    }
                }()
                
                HStack(spacing: 20) {
                    Image(systemName: "visionpro.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Platform")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text(platform)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                let isPremium: Bool = {
                    if let visionOSDataManager = viewModel.dataManagerInstance as? VisionOSDataManager {
                        return visionOSDataManager.isPremium
                    } else if let regularDataManager = viewModel.dataManagerInstance as? DataManager {
                        return regularDataManager.isPremium
                    } else {
                        return false
                    }
                }()
                
                HStack(spacing: 20) {
                    Image(systemName: "crown.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Premium Status")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text(isPremium ? "Premium" : "Free")
                            .font(.title2)
                            .foregroundStyle(isPremium ? .green : .orange)
                    }
                    
                    Spacer()
                }
            } header: {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Account")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            Section {
                HStack(spacing: 20) {
                    Image(systemName: "paintbrush.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Theme")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text(themeManager.colorScheme == .dark ? "Dark" : themeManager.colorScheme == .light ? "Light" : "Auto")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("Theme", selection: $themeManager.colorScheme) {
                        Text("Light").tag(ColorScheme.light)
                        Text("Dark").tag(ColorScheme.dark)
                        Text("Auto").tag(nil as ColorScheme?)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            } header: {
                HStack {
                    Image(systemName: "paintbrush.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Appearance")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            Section {
                HStack(spacing: 20) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Version")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text(versionManager.fullVersionString)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                Button {
                    showChangelog = true
                } label: {
                    HStack(spacing: 20) {
                        Image(systemName: "list.bullet.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.title2)
                        Text("Changelog")
                            .font(.title3)
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            } header: {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("About")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showChangelog) {
            ChangelogView(versionManager: versionManager)
        }
    }
}

// MARK: - Helper Views
struct ChangelogView: View {
    @ObservedObject var versionManager: AppVersionManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("What's New in \(versionManager.fullVersionString)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("✨ New Features")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("• Enhanced spatial computing experience")
                        Text("• Improved hand tracking integration")
                        Text("• Better performance on visionOS")
                        Text("• Local data storage (no Firebase dependency)")
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("🐛 Bug Fixes")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("• Fixed visionOS compatibility issues")
                        Text("• Improved stability and performance")
                        Text("• Enhanced user interface responsiveness")
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("🔧 Technical Improvements")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("• Removed Firebase dependencies for visionOS")
                        Text("• Optimized for spatial computing")
                        Text("• Enhanced SwiftData integration")
                        Text("• Improved CloudKit synchronization")
                    }
                }
                .padding()
            }
            .navigationTitle("Changelog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Premium Upgrade View
struct VisionPremiumUpgradeView: View {
    @ObservedObject var viewModel: VisionOSAppViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundStyle(.linearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("Upgrade to Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Unlock all features and screens")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Features
                    VStack(spacing: 20) {
                        Text("Premium Features")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            VisionFeatureRow(icon: "square.grid.2x2.fill", text: "Access all 10 screens")
                            VisionFeatureRow(icon: "antenna.radiowaves.left.and.right", text: "Advanced connectivity")
                            VisionFeatureRow(icon: "crown.fill", text: "Premium support")
                            VisionFeatureRow(icon: "star.fill", text: "Exclusive features")
                        }
                    }
                    
                    // Upgrade Button
                    Button("Upgrade Now") {
                        viewModel.unlockPremium()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.linearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .fontWeight(.semibold)
                    
                    // Promo Code
                    Button("Have a promo code?") {
                        viewModel.showPromoCode = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
                .padding()
            }
            .navigationTitle("Premium Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Vision Feature Row
struct VisionFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.yellow)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Promo Code View
struct VisionPromoCodeView: View {
    @ObservedObject var viewModel: VisionOSAppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var promoCode = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "gift.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.blue)
                    
                    Text("Enter Promo Code")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Unlock premium features")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                // Promo Code Input
                VStack(spacing: 16) {
                    TextField("Enter promo code", text: $promoCode)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                
                // Apply Button
                Button("Apply Code") {
                    viewModel.applyPromoCode(promoCode)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .fontWeight(.semibold)
                .disabled(promoCode.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Promo Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
} 
