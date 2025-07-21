import SwiftUI

#if os(tvOS)
struct tvOSEntryView: View {
    @StateObject private var viewModel: AppViewModel
    @State private var selectedTab = 0
    
    init(dataManager: HybridDataManager) {
        self._viewModel = StateObject(wrappedValue: AppViewModel(dataManager: dataManager))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationView {
                TVHomeView(viewModel: viewModel)
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            // Screens Tab
            NavigationView {
                TVScreensView(viewModel: viewModel)
            }
            .tabItem {
                Image(systemName: "square.grid.2x2.fill")
                Text("Screens")
            }
            .tag(1)
            
            // Connect Tab
            NavigationView {
                TVConnectView(viewModel: viewModel)
            }
            .tabItem {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Text("Connect")
            }
            .tag(2)
            
            // Settings Tab
            NavigationView {
                TVSettingsView(viewModel: viewModel)
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(3)
        }
        .sheet(isPresented: $viewModel.showPremiumUpgrade) {
            TVPremiumUpgradeView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showPromoCode) {
            TVPromoCodeView(viewModel: viewModel)
        }
        .alert("Message", isPresented: $viewModel.showAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

// MARK: - TV Home View
struct TVHomeView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "infinity.circle.fill")
                        .font(.system(size: 120, weight: .medium))
                        .foregroundStyle(.linearGradient(
                            colors: [.orange, .red, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                    
                    Text("Infinitum Horizon")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Apple TV Edition")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                // Quick Actions
                VStack(spacing: 30) {
                    HStack {
                        Image(systemName: "bolt.circle.fill")
                            .font(.title)
                            .foregroundStyle(.linearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("Quick Actions")
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 30) {
                        TVQuickActionCard(
                            icon: "1.circle.fill",
                            title: "Screen 1",
                            subtitle: "Free",
                            color: .blue
                        ) {
                            viewModel.navigateToScreen(1)
                        }
                        
                        TVQuickActionCard(
                            icon: "2.circle.fill",
                            title: "Screen 2",
                            subtitle: "Free",
                            color: .green
                        ) {
                            viewModel.navigateToScreen(2)
                        }
                        
                        TVQuickActionCard(
                            icon: "3.circle.fill",
                            title: "Screen 3",
                            subtitle: "Premium",
                            color: .purple
                        ) {
                            viewModel.navigateToScreen(3)
                        }
                        
                        TVQuickActionCard(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "Connect",
                            subtitle: "Devices",
                            color: .orange
                        ) {
                            // Navigate to connect tab
                        }
                        
                        TVQuickActionCard(
                            icon: "gear.circle.fill",
                            title: "Settings",
                            subtitle: "Configure",
                            color: .gray
                        ) {
                            // Navigate to settings tab
                        }
                        
                        TVQuickActionCard(
                            icon: "crown.circle.fill",
                            title: "Premium",
                            subtitle: "Upgrade",
                            color: .yellow
                        ) {
                            viewModel.showPremiumUpgrade = true
                        }
                    }
                }
                
                // Apple TV Features
                VStack(spacing: 30) {
                    HStack {
                        Image(systemName: "tv.circle.fill")
                            .font(.title)
                            .foregroundStyle(.linearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("Apple TV Features")
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 20) {
                        ForEach(viewModel.getPlatformSpecificFeatures(), id: \.self) { feature in
                            HStack(spacing: 20) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.title2)
                                
                                Text(feature)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 20)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                }
                
                // Premium Upgrade
                if !viewModel.dataManagerInstance.isPremium {
                    VStack(spacing: 25) {
                        HStack {
                            Image(systemName: "crown.circle.fill")
                                .font(.title)
                                .foregroundStyle(.linearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            
                            Text("Upgrade to Premium")
                                .font(.title)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Unlock all 10 screens and remove ads")
                            .font(.title3)
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
                    .padding(40)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 40)
        }
        .background(.ultraThinMaterial)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - TV Screens View
struct TVScreensView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        List {
            Section {
                TVScreenRow(
                    number: 1,
                    title: "Device Connectivity",
                    subtitle: "Multipeer connectivity and messaging",
                    isPremium: false,
                    viewModel: viewModel
                )
                
                TVScreenRow(
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
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            Section {
                ForEach(3...10, id: \.self) { screenNumber in
                    TVScreenRow(
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
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .navigationTitle("Screens")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - TV Connect View
struct TVConnectView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var messageText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Connection Status
                VStack(spacing: 30) {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                            .font(.title)
                            .foregroundStyle(.linearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("Device Connectivity")
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 50) {
                        VStack(spacing: 15) {
                            Image(systemName: viewModel.multipeerManager.isHosting ? "antenna.radiowaves.left.and.right.circle.fill" : "antenna.radiowaves.left.and.right.circle")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundStyle(viewModel.multipeerManager.isHosting ? .green : .gray)
                                .symbolEffect(.bounce, options: .repeating, value: viewModel.multipeerManager.isHosting)
                            
                            Text("Host")
                                .font(.title2)
                                .fontWeight(.medium)
                        }
                        
                        VStack(spacing: 15) {
                            Image(systemName: viewModel.multipeerManager.isBrowsing ? "antenna.radiowaves.left.and.right.circle.fill" : "antenna.radiowaves.left.and.right.circle")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundStyle(viewModel.multipeerManager.isBrowsing ? .blue : .gray)
                                .symbolEffect(.bounce, options: .repeating, value: viewModel.multipeerManager.isBrowsing)
                            
                            Text("Browse")
                                .font(.title2)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                // Connection Controls
                VStack(spacing: 25) {
                    HStack(spacing: 20) {
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
                    VStack(spacing: 25) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Connected Devices")
                                .font(.title)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 15) {
                            ForEach(viewModel.multipeerManager.connectedPeers, id: \.self) { peer in
                                HStack(spacing: 20) {
                                    Image(systemName: "tv")
                                        .foregroundStyle(.green)
                                        .font(.title2)
                                    
                                    Text(peer.displayName)
                                        .font(.title3)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 30)
                                .padding(.vertical, 20)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                        }
                    }
                }
                
                // Message Sending
                VStack(spacing: 25) {
                    HStack {
                        Image(systemName: "message.circle.fill")
                            .font(.title)
                            .foregroundStyle(.linearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("Send Message")
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 15) {
                        TextField("Enter message", text: $messageText)
                            .textFieldStyle(.roundedBorder)
                            .font(.title3)
                        
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
                    VStack(spacing: 25) {
                        HStack {
                            Image(systemName: "envelope.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Received Messages")
                                .font(.title)
                                .fontWeight(.semibold)
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(viewModel.multipeerManager.receivedMessages, id: \.self) { message in
                                    HStack {
                                        Text(message)
                                            .font(.title3)
                                            .fontWeight(.medium)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 20)
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 40)
        }
        .background(.ultraThinMaterial)
        .navigationTitle("Connect")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - TV Settings View
struct TVSettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        List {
            Section {
                HStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text(viewModel.dataManagerInstance.currentUser?.username ?? "Unknown")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    Image(systemName: "tv.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Platform")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text(viewModel.dataManagerInstance.currentUser?.platform ?? "Unknown")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    Image(systemName: viewModel.dataManagerInstance.isPremium ? "crown.circle.fill" : "person.circle")
                        .foregroundStyle(viewModel.dataManagerInstance.isPremium ? .yellow : .orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Premium Status")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text(viewModel.dataManagerInstance.isPremium ? "Premium" : "Free")
                            .font(.title2)
                            .foregroundStyle(viewModel.dataManagerInstance.isPremium ? .green : .orange)
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
                if !viewModel.dataManagerInstance.isPremium {
                    Button {
                        viewModel.showPremiumUpgrade = true
                    } label: {
                        HStack(spacing: 20) {
                            Image(systemName: "crown.circle.fill")
                                .foregroundStyle(.yellow)
                                .font(.title2)
                            Text("Upgrade to Premium")
                                .font(.title3)
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    
                    Button {
                        viewModel.showPromoCode = true
                    } label: {
                        HStack(spacing: 20) {
                            Image(systemName: "ticket.circle.fill")
                                .foregroundStyle(.orange)
                                .font(.title2)
                            Text("Enter Promo Code")
                                .font(.title3)
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                } else {
                    HStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title2)
                        Text("Premium Active")
                            .font(.title3)
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            } header: {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("Premium")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            Section {
                ForEach(viewModel.getPlatformSpecificFeatures(), id: \.self) { feature in
                    HStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title2)
                        Text(feature)
                            .font(.title3)
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            } header: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Features")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            Section {
                HStack(spacing: 20) {
                    Image(systemName: themeManager.themeMode.icon)
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Appearance")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text(themeManager.themeMode.description)
                            .font(.title2)
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
                            .font(.title2)
                    }
                }
            } header: {
                HStack {
                    Image(systemName: "paintbrush.fill")
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
                        Text(AppVersionManager.shared.fullVersionString)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    Image(systemName: "hammer.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Build")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text(AppVersionManager.shared.buildString)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
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
    }
}

// MARK: - Helper Views
struct TVQuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(color)
                
                VStack(spacing: 10) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(30)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TVScreenRow: View {
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
            HStack(spacing: 20) {
                Image(systemName: "\(number).circle.fill")
                    .font(.title)
                    .foregroundStyle(isPremium ? .purple : .blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isPremium && !viewModel.dataManagerInstance.isPremium {
                    Image(systemName: "lock.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.title)
                }
            }
            .padding(.vertical, 15)
        }
        .disabled(isPremium && !viewModel.dataManagerInstance.isPremium)
    }
}

// MARK: - TV Premium Views
struct TVPremiumUpgradeView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 20) {
                        Image(systemName: "crown.circle.fill")
                            .font(.system(size: 120, weight: .medium))
                            .foregroundStyle(.linearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))

                        
                        Text("Upgrade to Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("Unlock all features and remove ads")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Premium Features
                    VStack(spacing: 30) {
                        HStack {
                            Image(systemName: "sparkles.circle.fill")
                                .font(.title)
                                .foregroundStyle(.linearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            
                            Text("Premium Features")
                                .font(.title)
                                .fontWeight(.semibold)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            PremiumFeatureCard(icon: "1.circle.fill", title: "All 10 Screens", color: .blue)
                            PremiumFeatureCard(icon: "xmark.circle.fill", title: "No Ads", color: .green)
                            PremiumFeatureCard(icon: "cloud.circle.fill", title: "Cloud Sync", color: .cyan)
                            PremiumFeatureCard(icon: "gear.circle.fill", title: "Advanced Settings", color: .orange)
                            PremiumFeatureCard(icon: "chart.circle.fill", title: "Analytics", color: .purple)
                            PremiumFeatureCard(icon: "person.3.circle.fill", title: "Team Features", color: .pink)
                        }
                    }
                    
                    // Pricing
                    VStack(spacing: 25) {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.title)
                                .foregroundStyle(.linearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            
                            Text("Pricing")
                                .font(.title)
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 30) {
                            PricingOption(
                                title: "Monthly",
                                price: "$4.99",
                                period: "per month",
                                isPopular: false
                            ) {
                                viewModel.upgradeToPremium(plan: "monthly")
                                dismiss()
                            }
                            
                            PricingOption(
                                title: "Yearly",
                                price: "$39.99",
                                period: "per year",
                                isPopular: true,
                                savings: "Save 33%"
                            ) {
                                viewModel.upgradeToPremium(plan: "yearly")
                                dismiss()
                            }
                        }
                    }
                    
                    // Terms
                    VStack(spacing: 20) {
                        Text("Terms & Conditions")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Premium subscription will automatically renew unless cancelled at least 24 hours before the end of the current period. You can manage your subscriptions in your device's account settings.")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(30)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 40)
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Premium Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

struct TVPromoCodeView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var promoCode = ""
    @State private var isValidating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "ticket.circle.fill")
                        .font(.system(size: 120, weight: .medium))
                        .foregroundStyle(.linearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("Enter Promo Code")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Redeem your promotional code for premium access")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                // Promo Code Input
                VStack(spacing: 30) {
                    HStack {
                        Image(systemName: "ticket.circle.fill")
                            .font(.title)
                            .foregroundStyle(.orange)
                        
                        Text("Promo Code")
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(spacing: 20) {
                        TextField("Enter your promo code", text: $promoCode)
                            .textFieldStyle(.roundedBorder)
                            .font(.title2)
                            .fontWeight(.medium)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        
                        Button("Redeem Code") {
                            isValidating = true
                            viewModel.redeemPromoCode(promoCode) { success in
                                isValidating = false
                                if success {
                                    dismiss()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .fontWeight(.medium)
                        .disabled(promoCode.isEmpty || isValidating)
                        
                        if isValidating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Validating code...")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Available Promo Codes
                VStack(spacing: 25) {
                    HStack {
                        Image(systemName: "gift.circle.fill")
                            .font(.title)
                            .foregroundStyle(.green)
                        
                        Text("Available Codes")
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(spacing: 15) {
                        PromoCodeExample(code: "WELCOME50", description: "50% off first month")
                        PromoCodeExample(code: "FREETRIAL", description: "7-day free trial")
                        PromoCodeExample(code: "LAUNCH25", description: "25% off yearly plan")
                    }
                }
                
                Spacer()
                
                // Close Button
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .fontWeight(.medium)
            }
            .padding(.horizontal, 40)
            .background(.ultraThinMaterial)
            .navigationTitle("Promo Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}
#endif 