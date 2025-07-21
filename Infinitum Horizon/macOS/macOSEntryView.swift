import SwiftUI

struct macOSEntryView: View {
    @StateObject private var viewModel: AppViewModel
    @State private var selectedSidebarItem: String? = "home"
    
    init(dataManager: HybridDataManager) {
        self._viewModel = StateObject(wrappedValue: AppViewModel(dataManager: dataManager))
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedSidebarItem) {
                Section("Main") {
                    NavigationLink(value: "home") {
                        Label("Home", systemImage: "house.fill")
                    }
                    
                    NavigationLink(value: "screens") {
                        Label("Screens", systemImage: "square.grid.2x2.fill")
                    }
                    
                    NavigationLink(value: "connect") {
                        Label("Connect", systemImage: "antenna.radiowaves.left.and.right")
                    }
                }
                
                Section("Free Screens") {
                    NavigationLink(value: "screen1") {
                        Label("Screen 1", systemImage: "1.circle.fill")
                    }
                    
                    NavigationLink(value: "screen2") {
                        Label("Screen 2", systemImage: "2.circle.fill")
                    }
                }
                
                Section("Premium Screens") {
                    ForEach(3...10, id: \.self) { screenNumber in
                        NavigationLink(value: "screen\(screenNumber)") {
                            Label("Screen \(screenNumber)", systemImage: "\(screenNumber).circle.fill")
                        }
                        .disabled(!viewModel.canAccessScreen(screenNumber))
                    }
                }
                
                Section("Settings") {
                    NavigationLink(value: "settings") {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    if !viewModel.dataManagerInstance.isPremium {
                        NavigationLink(value: "premium") {
                            Label("Upgrade to Premium", systemImage: "crown.fill")
                        }
                    }
                }
            }
            .navigationTitle("Infinitum Horizon")
        } detail: {
            // Detail view
            Group {
                switch selectedSidebarItem {
                case "home":
                    macOSHomeView(viewModel: viewModel, selectedSidebarItem: $selectedSidebarItem)
                case "screens":
                    macOSScreensView(viewModel: viewModel, selectedSidebarItem: $selectedSidebarItem)
                case "connect":
                    macOSConnectView(viewModel: viewModel)
                case "screen1":
                    Screen1View(viewModel: viewModel)
                case "screen2":
                    Screen2View(viewModel: viewModel)
                case "settings":
                    macOSSettingsView(viewModel: viewModel)
                case "premium":
                    PremiumUpgradeView(viewModel: viewModel)
                default:
                    if let screenValue = selectedSidebarItem,
                       screenValue.hasPrefix("screen"),
                       let screenNumber = Int(screenValue.replacingOccurrences(of: "screen", with: "")) {
                        PremiumScreenView(screenNumber: screenNumber, viewModel: viewModel)
                    } else {
                        macOSHomeView(viewModel: viewModel, selectedSidebarItem: $selectedSidebarItem)
                    }
                }
            }
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
    }
}

// MARK: - macOS Home View
struct macOSHomeView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var selectedSidebarItem: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "infinity.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.linearGradient(
                            colors: [.orange, .red, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("Infinitum Horizon")
                        .font(.system(size: 48, weight: .bold))
                    
                    Text("macOS Edition")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Quick Actions Grid
                VStack(spacing: 30) {
                    Text("Quick Actions")
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        macOSQuickActionCard(
                            icon: "1.circle.fill",
                            title: "Screen 1",
                            subtitle: "Device Connectivity",
                            color: .blue
                        ) {
                            selectedSidebarItem = "screen1"
                        }
                        
                        macOSQuickActionCard(
                            icon: "2.circle.fill",
                            title: "Screen 2",
                            subtitle: "Session Management",
                            color: .green
                        ) {
                            selectedSidebarItem = "screen2"
                        }
                        
                        macOSQuickActionCard(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "Connect",
                            subtitle: "Multi-device Sync",
                            color: .orange
                        ) {
                            selectedSidebarItem = "connect"
                        }
                        
                        macOSQuickActionCard(
                            icon: "3.circle.fill",
                            title: "Screen 3",
                            subtitle: "Premium Features",
                            color: .purple
                        ) {
                            selectedSidebarItem = "screen3"
                        }
                        
                        macOSQuickActionCard(
                            icon: "cloud.fill",
                            title: "CloudKit",
                            subtitle: "Data Sync",
                            color: .cyan
                        ) {
                            selectedSidebarItem = "screen2" // Screen 2 has CloudKit sync
                        }
                        
                        macOSQuickActionCard(
                            icon: "gear",
                            title: "Settings",
                            subtitle: "Configuration",
                            color: .gray
                        ) {
                            selectedSidebarItem = "settings"
                        }
                    }
                }
                
                // macOS Features
                VStack(spacing: 30) {
                    Text("macOS Features")
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        ForEach(viewModel.getPlatformSpecificFeatures(), id: \.self) { feature in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                Text(feature)
                                    .font(.title3)
                                Spacer()
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                
                // Premium Upgrade
                if !viewModel.dataManagerInstance.isPremium {
                    VStack(spacing: 20) {
                        Text("Upgrade to Premium")
                            .font(.title)
                        
                        Text("Unlock all 10 screens and remove ads")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            Button("Upgrade Now") {
                                viewModel.showPremiumUpgrade = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            
                            Button("Enter Promo Code") {
                                viewModel.showPromoCode = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }
                    .padding(40)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 40)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - macOS Screens View
struct macOSScreensView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var selectedSidebarItem: String?
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Available Screens")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    // Free Screens
                    Group {
                        macOSScreenCard(
                            number: 1,
                            title: "Device Connectivity",
                            subtitle: "Multipeer connectivity and messaging",
                            isPremium: false,
                            viewModel: viewModel,
                            selectedSidebarItem: $selectedSidebarItem
                        )
                        
                        macOSScreenCard(
                            number: 2,
                            title: "Session Management",
                            subtitle: "Create and join sessions",
                            isPremium: false,
                            viewModel: viewModel,
                            selectedSidebarItem: $selectedSidebarItem
                        )
                    }
                    
                    // Premium Screens
                    ForEach(3...10, id: \.self) { screenNumber in
                        macOSScreenCard(
                            number: screenNumber,
                            title: "Advanced Features",
                            subtitle: "Exclusive premium content",
                            isPremium: true,
                            viewModel: viewModel,
                            selectedSidebarItem: $selectedSidebarItem
                        )
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - macOS Connect View
struct macOSConnectView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var messageText = ""
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Device Connectivity")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Connection Status
            HStack(spacing: 60) {
                VStack(spacing: 15) {
                    Image(systemName: viewModel.multipeerManager.isHosting ? "antenna.radiowaves.left.and.right.circle.fill" : "antenna.radiowaves.left.and.right.circle")
                        .font(.system(size: 60))
                        .foregroundColor(viewModel.multipeerManager.isHosting ? .green : .gray)
                    
                    Text("Hosting")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(viewModel.multipeerManager.isHosting ? "Active" : "Inactive")
                        .foregroundColor(viewModel.multipeerManager.isHosting ? .green : .secondary)
                }
                
                VStack(spacing: 15) {
                    Image(systemName: viewModel.multipeerManager.isBrowsing ? "antenna.radiowaves.left.and.right.circle.fill" : "antenna.radiowaves.left.and.right.circle")
                        .font(.system(size: 60))
                        .foregroundColor(viewModel.multipeerManager.isBrowsing ? .blue : .gray)
                    
                    Text("Browsing")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(viewModel.multipeerManager.isBrowsing ? "Active" : "Inactive")
                        .foregroundColor(viewModel.multipeerManager.isBrowsing ? .blue : .secondary)
                }
            }
            
            // Connection Controls
            HStack(spacing: 20) {
                Button("Start Hosting") {
                    viewModel.startHosting()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.multipeerManager.isHosting)
                
                Button("Start Browsing") {
                    viewModel.startBrowsing()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(viewModel.multipeerManager.isBrowsing)
                
                if viewModel.multipeerManager.isHosting || viewModel.multipeerManager.isBrowsing {
                    Button("Disconnect") {
                        viewModel.stopConnection()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .foregroundColor(.red)
                }
            }
            
            // Connected Devices
            if !viewModel.multipeerManager.connectedPeers.isEmpty {
                VStack(spacing: 20) {
                    Text("Connected Devices")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        ForEach(viewModel.multipeerManager.connectedPeers, id: \.self) { peer in
                            HStack {
                                Image(systemName: "macbook")
                                    .foregroundColor(.green)
                                Text(peer.displayName)
                                Spacer()
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            
            // Message Sending
            VStack(spacing: 20) {
                Text("Send Message")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack {
                    TextField("Enter message", text: $messageText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)
                    
                    Button("Send") {
                        viewModel.sendMessage(messageText)
                        messageText = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(messageText.isEmpty)
                }
            }
            
            // Received Messages
            if !viewModel.multipeerManager.receivedMessages.isEmpty {
                VStack(spacing: 20) {
                    Text("Received Messages")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.multipeerManager.receivedMessages, id: \.self) { message in
                                Text(message)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
            
            Spacer()
        }
        .padding(40)
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - macOS Settings View
struct macOSSettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Form {
                Section("Account") {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(viewModel.dataManagerInstance.currentUser?.username ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Platform")
                        Spacer()
                        Text(viewModel.dataManagerInstance.currentUser?.platform ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Premium Status")
                        Spacer()
                        Text(viewModel.dataManagerInstance.isPremium ? "Premium" : "Free")
                            .foregroundColor(viewModel.dataManagerInstance.isPremium ? .green : .orange)
                    }
                }
                
                Section("Premium") {
                    if !viewModel.dataManagerInstance.isPremium {
                        Button("Upgrade to Premium") {
                            viewModel.showPremiumUpgrade = true
                        }
                        
                        Button("Enter Promo Code") {
                            viewModel.showPromoCode = true
                        }
                    } else {
                        HStack {
                            Text("Premium Active")
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Section("Features") {
                    ForEach(viewModel.getPlatformSpecificFeatures(), id: \.self) { feature in
                        HStack {
                            Text(feature)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Section("Appearance") {
                    HStack {
                        Text("Theme")
                        Spacer()
                        Picker("Theme", selection: $themeManager.themeMode) {
                            ForEach(ThemeManager.ThemeMode.allCases, id: \.self) { mode in
                                HStack {
                                    Image(systemName: mode.icon)
                                    Text(mode.rawValue)
                                }
                                .tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: themeManager.themeMode) { _, newValue in
                            themeManager.setThemeMode(newValue)
                        }
                    }
                    
                    HStack {
                        Text("Description")
                        Spacer()
                        Text(themeManager.themeMode.description)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

// MARK: - Helper Views
struct macOSQuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(30)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct macOSScreenCard: View {
    let number: Int
    let title: String
    let subtitle: String
    let isPremium: Bool
    @ObservedObject var viewModel: AppViewModel
    @Binding var selectedSidebarItem: String?
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "\(number).circle.fill")
                    .font(.title)
                    .foregroundColor(isPremium ? .purple : .blue)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isPremium && !viewModel.dataManagerInstance.isPremium {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                }
            }
            
            if isPremium && !viewModel.dataManagerInstance.isPremium {
                Button("Upgrade to Access") {
                    viewModel.showPremiumUpgrade = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Button("Open") {
                    selectedSidebarItem = "screen\(number)"
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
} 
