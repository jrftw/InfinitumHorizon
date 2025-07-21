import SwiftUI

struct iOSEntryView: View {
    @StateObject private var viewModel: AppViewModel
    @StateObject private var adManager = AdManager.shared
    @State private var selectedTab = 0
    
    init(dataManager: HybridDataManager) {
        self._viewModel = StateObject(wrappedValue: AppViewModel(dataManager: dataManager))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationStack {
                HomeView(viewModel: viewModel, selectedTab: $selectedTab)
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            // Screens Tab
            NavigationStack {
                ScreensView(viewModel: viewModel)
            }
            .tabItem {
                Image(systemName: "square.grid.2x2.fill")
                Text("Screens")
            }
            .tag(1)
            
            // Connect Tab
            NavigationStack {
                ConnectView(viewModel: viewModel)
            }
            .tabItem {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Text("Connect")
            }
            .tag(2)
            
            // Cross-Device Control Tab
            NavigationStack {
                CrossDeviceControlView(viewModel: viewModel)
            }
            .tabItem {
                Image(systemName: "iphone.gen3.circle")
                Text("Control")
            }
            .tag(3)
            
            // Settings Tab
            NavigationStack {
                SettingsView(viewModel: viewModel)
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(4)
        }
        .sheet(isPresented: $viewModel.showPremiumUpgrade) {
            PremiumUpgradeView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showPromoCode) {
            PromoCodeView(viewModel: viewModel)
        }
        .alert("Message", isPresented: $viewModel.showAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .onAppear {
            adManager.setDataManager(viewModel.dataManagerInstance)
            adManager.loadBannerAd()
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var selectedTab: Int
    @ObservedObject var adManager = AdManager.shared
    
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
                    
                    Text("iOS Edition")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Quick Actions
                VStack(spacing: 24) {
                    HStack {
                        Image(systemName: "bolt.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.linearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("Quick Actions")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        QuickActionCard(
                            icon: "1.circle.fill",
                            title: "Screen 1",
                            subtitle: "Free",
                            color: .blue
                        ) {
                            selectedTab = 1 // Navigate to screens tab
                            // The actual navigation to screen 1 will be handled in ScreensView
                        }
                        
                        QuickActionCard(
                            icon: "2.circle.fill",
                            title: "Screen 2",
                            subtitle: "Free",
                            color: .green
                        ) {
                            selectedTab = 1 // Navigate to screens tab
                            // The actual navigation to screen 2 will be handled in ScreensView
                        }
                        
                        QuickActionCard(
                            icon: "3.circle.fill",
                            title: "Screen 3",
                            subtitle: "Premium",
                            color: .purple
                        ) {
                            selectedTab = 1 // Navigate to screens tab
                            // The actual navigation to screen 3 will be handled in ScreensView
                        }
                        
                        QuickActionCard(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "Connect",
                            subtitle: "Devices",
                            color: .orange
                        ) {
                            selectedTab = 2 // Navigate to connect tab
                        }
                    }
                }
                
                // iOS Features
                VStack(spacing: 24) {
                    HStack {
                        Image(systemName: "iphone.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.linearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("iOS Features")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 16) {
                        ForEach(viewModel.getPlatformSpecificFeatures(), id: \.self) { feature in
                            HStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.title3)
                                
                                Text(feature)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                
                // Premium Upgrade
                if !viewModel.dataManagerInstance.isPremium {
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "crown.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.linearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            
                            Text("Upgrade to Premium")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Unlock all 10 screens and remove ads")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Upgrade Now") {
                            viewModel.showPremiumUpgrade = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .fontWeight(.medium)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                // Banner Ad
                AdBannerView()
                
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
        }
        .background(.ultraThinMaterial)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Screens View
struct ScreensView: View {
    @ObservedObject var viewModel: AppViewModel
    @ObservedObject var adManager = AdManager.shared
    
    var body: some View {
        List {
            Section {
                ScreenRow(
                    number: 1,
                    title: "Device Connectivity",
                    subtitle: "Multipeer connectivity and messaging",
                    isPremium: false,
                    viewModel: viewModel
                )
                
                ScreenRow(
                    number: 2,
                    title: "Session Management",
                    subtitle: "Create and join sessions",
                    isPremium: false,
                    viewModel: viewModel
                )
            } header: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Free Screens")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            
            Section {
                ForEach(3...10, id: \.self) { screenNumber in
                    ScreenRow(
                        number: screenNumber,
                        title: "Advanced Features",
                        subtitle: "Exclusive premium content",
                        isPremium: true,
                        viewModel: viewModel
                    )
                }
            } header: {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("Premium Screens")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .navigationTitle("Screens")
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .bottom) {
            AdBannerView()
        }
    }
}

// MARK: - Connect View
struct ConnectView: View {
    @ObservedObject var viewModel: AppViewModel
    @ObservedObject var adManager = AdManager.shared
    @State private var messageText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Connection Status
                VStack(spacing: 24) {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.linearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("Device Connectivity")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 32) {
                        VStack(spacing: 12) {
                            Image(systemName: viewModel.multipeerManager.isHosting ? "antenna.radiowaves.left.and.right.circle.fill" : "antenna.radiowaves.left.and.right.circle")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundStyle(viewModel.multipeerManager.isHosting ? .green : .gray)

                            
                            Text("Host")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(spacing: 12) {
                            Image(systemName: viewModel.multipeerManager.isBrowsing ? "antenna.radiowaves.left.and.right.circle.fill" : "antenna.radiowaves.left.and.right.circle")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundStyle(viewModel.multipeerManager.isBrowsing ? .blue : .gray)

                            
                            Text("Browse")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                // Connection Controls
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        Button("Start Hosting") {
                            viewModel.startHosting()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .fontWeight(.medium)
                        .disabled(viewModel.multipeerManager.isHosting)
                        
                        Button("Start Browsing") {
                            viewModel.startBrowsing()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .fontWeight(.medium)
                        .disabled(viewModel.multipeerManager.isBrowsing)
                    }
                    
                    if viewModel.multipeerManager.isHosting || viewModel.multipeerManager.isBrowsing {
                        Button("Disconnect") {
                            viewModel.stopConnection()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    }
                }
                
                // Connected Devices
                if !viewModel.multipeerManager.connectedPeers.isEmpty {
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Connected Devices")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.multipeerManager.connectedPeers, id: \.self) { peer in
                                HStack(spacing: 16) {
                                    Image(systemName: "iphone")
                                        .foregroundStyle(.green)
                                        .font(.title3)
                                    
                                    Text(peer.displayName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                }
                
                // Message Sending
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "message.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.linearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("Send Message")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 12) {
                        TextField("Enter message", text: $messageText)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                        
                        Button("Send") {
                            viewModel.sendMessage(messageText)
                            messageText = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .fontWeight(.medium)
                        .disabled(messageText.isEmpty)
                    }
                }
                
                // Received Messages
                if !viewModel.multipeerManager.receivedMessages.isEmpty {
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "envelope.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Received Messages")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.multipeerManager.receivedMessages, id: \.self) { message in
                                    HStack {
                                        Text(message)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
                
                Spacer(minLength: 32)
                
                // Banner Ad
                AdBannerView()
            }
            .padding(.horizontal, 20)
        }
        .background(.ultraThinMaterial)
        .navigationTitle("Connect")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var adManager = AdManager.shared
    
    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Username")
                            .font(.body)
                            .fontWeight(.medium)
                        Text(viewModel.dataManagerInstance.currentUser?.username ?? "Unknown")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    Image(systemName: "iphone.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Platform")
                            .font(.body)
                            .fontWeight(.medium)
                        Text(viewModel.dataManagerInstance.currentUser?.platform ?? "Unknown")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    Image(systemName: viewModel.dataManagerInstance.isPremium ? "crown.circle.fill" : "person.circle")
                        .foregroundStyle(viewModel.dataManagerInstance.isPremium ? .yellow : .orange)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Premium Status")
                            .font(.body)
                            .fontWeight(.medium)
                        Text(viewModel.dataManagerInstance.isPremium ? "Premium" : "Free")
                            .font(.subheadline)
                            .foregroundStyle(viewModel.dataManagerInstance.isPremium ? .green : .orange)
                    }
                    
                    Spacer()
                }
            } header: {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Account")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            
            Section {
                if !viewModel.dataManagerInstance.isPremium {
                    Button {
                        viewModel.showPremiumUpgrade = true
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "crown.circle.fill")
                                .foregroundStyle(.yellow)
                                .font(.title3)
                            Text("Upgrade to Premium")
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    
                    Button {
                        viewModel.showPromoCode = true
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "ticket.circle.fill")
                                .foregroundStyle(.orange)
                                .font(.title3)
                            Text("Enter Promo Code")
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                } else {
                    HStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                        Text("Premium Active")
                            .font(.body)
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            } header: {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("Premium")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            
            Section {
                ForEach(viewModel.getPlatformSpecificFeatures(), id: \.self) { feature in
                    HStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                        Text(feature)
                            .font(.body)
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            } header: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Features")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            
            Section {
                HStack(spacing: 16) {
                    Image(systemName: themeManager.themeMode.icon)
                        .foregroundStyle(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Appearance")
                            .font(.body)
                            .fontWeight(.medium)
                        Text(themeManager.themeMode.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Menu {
                        ForEach(ThemeManager.ThemeMode.allCases, id: \.self) { mode in
                            Button(action: {
                                themeManager.setThemeMode(mode)
                            }) {
                                HStack {
                                    Image(systemName: mode.icon)
                                    Text(mode.rawValue)
                                    if mode == themeManager.themeMode {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundStyle(.blue)
                            .font(.title3)
                    }
                }
            } header: {
                HStack {
                    Image(systemName: "paintbrush.fill")
                        .foregroundStyle(.blue)
                    Text("Appearance")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Version")
                            .font(.body)
                            .fontWeight(.medium)
                        Text("1.0.0")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    Image(systemName: "hammer.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Build")
                            .font(.body)
                            .fontWeight(.medium)
                        Text("1")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            } header: {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("About")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .bottom) {
            AdBannerView()
        }
    }
}

// MARK: - Helper Views
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(color)

                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ScreenRow: View {
    let number: Int
    let title: String
    let subtitle: String
    let isPremium: Bool
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        NavigationLink(destination: {
            if number <= 2 {
                if number == 1 {
                    Screen1View(viewModel: viewModel)
                } else {
                    Screen2View(viewModel: viewModel)
                }
            } else {
                PremiumScreenView(screenNumber: number, viewModel: viewModel)
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: "\(number).circle.fill")
                    .font(.title2)
                    .foregroundStyle(isPremium ? .purple : .blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isPremium && !viewModel.dataManagerInstance.isPremium {
                    Image(systemName: "lock.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
        }
        .disabled(isPremium && !viewModel.dataManagerInstance.isPremium)
    }
} 
