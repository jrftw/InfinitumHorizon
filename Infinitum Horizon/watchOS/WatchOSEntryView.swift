import SwiftUI
import WatchConnectivity

struct WatchOSEntryView: View {
    @StateObject private var viewModel: AppViewModel
    @State private var selectedTab = 0
    
    init(dataManager: HybridDataManager) {
        self._viewModel = StateObject(wrappedValue: AppViewModel(dataManager: dataManager))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            WatchHomeView(viewModel: viewModel)
                .tag(0)
            
            // Screens Tab
            WatchScreensView(viewModel: viewModel)
                .tag(1)
            
            // Connect Tab
            WatchConnectView(viewModel: viewModel)
                .tag(2)
            
            // Settings Tab
            WatchSettingsView(viewModel: viewModel)
                .tag(3)
        }
        .tabViewStyle(.page)
        .sheet(isPresented: $viewModel.showPremiumUpgrade) {
            WatchPremiumUpgradeView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showPromoCode) {
            WatchPromoCodeView(viewModel: viewModel)
        }
        .alert("Message", isPresented: $viewModel.showAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

// MARK: - Watch Home View
struct WatchHomeView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "infinity.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.linearGradient(
                            colors: [.orange, .red, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("Infinitum")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Horizon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Quick Actions
                VStack(spacing: 15) {
                    Text("Quick Actions")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 10) {
                        WatchQuickActionButton(
                            icon: "1.circle.fill",
                            title: "Screen 1",
                            color: .blue
                        ) {
                            // Navigate to screen 1
                        }
                        
                        WatchQuickActionButton(
                            icon: "2.circle.fill",
                            title: "Screen 2",
                            color: .green
                        ) {
                            // Navigate to screen 2
                        }
                        
                        WatchQuickActionButton(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "Connect",
                            color: .orange
                        ) {
                            // Navigate to connect
                        }
                    }
                }
                
                // Premium Upgrade
                if !viewModel.dataManagerInstance.isPremium {
                    VStack(spacing: 10) {
                        Text("Upgrade to Premium")
                            .font(.headline)
                        
                        Button("Upgrade") {
                            viewModel.showPremiumUpgrade = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
}

// MARK: - Watch Screens View
struct WatchScreensView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Text("Screens")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Free Screens
                VStack(spacing: 10) {
                    Text("Free")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    WatchScreenButton(
                        number: 1,
                        title: "Connectivity",
                        isPremium: false,
                        viewModel: viewModel
                    )
                    
                    WatchScreenButton(
                        number: 2,
                        title: "Sessions",
                        isPremium: false,
                        viewModel: viewModel
                    )
                }
                
                // Premium Screens
                VStack(spacing: 10) {
                    Text("Premium")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(3...5, id: \.self) { screenNumber in
                        WatchScreenButton(
                            number: screenNumber,
                            title: "Advanced",
                            isPremium: true,
                            viewModel: viewModel
                        )
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Watch Connect View
struct WatchConnectView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var messageText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Connect")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Connection Status
                HStack(spacing: 20) {
                    VStack {
                        Image(systemName: viewModel.multipeerManager.isHosting ? "antenna.radiowaves.left.and.right.circle.fill" : "antenna.radiowaves.left.and.right.circle")
                            .font(.title2)
                            .foregroundColor(viewModel.multipeerManager.isHosting ? .green : .gray)
                        
                        Text("Host")
                            .font(.caption2)
                    }
                    
                    VStack {
                        Image(systemName: viewModel.multipeerManager.isBrowsing ? "antenna.radiowaves.left.and.right.circle.fill" : "antenna.radiowaves.left.and.right.circle")
                            .font(.title2)
                            .foregroundColor(viewModel.multipeerManager.isBrowsing ? .blue : .gray)
                        
                        Text("Browse")
                            .font(.caption2)
                    }
                }
                
                // Connection Controls
                VStack(spacing: 10) {
                    Button("Start Hosting") {
                        viewModel.startHosting()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(viewModel.multipeerManager.isHosting)
                    
                    Button("Start Browsing") {
                        viewModel.startBrowsing()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(viewModel.multipeerManager.isBrowsing)
                    
                    if viewModel.multipeerManager.isHosting || viewModel.multipeerManager.isBrowsing {
                        Button("Disconnect") {
                            viewModel.stopConnection()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .foregroundColor(.red)
                    }
                }
                
                // Connected Devices
                if !viewModel.multipeerManager.connectedPeers.isEmpty {
                    VStack(spacing: 10) {
                        Text("Connected")
                            .font(.headline)
                        
                        ForEach(viewModel.multipeerManager.connectedPeers, id: \.self) { peer in
                            HStack {
                                Image(systemName: "applewatch")
                                    .foregroundColor(.green)
                                Text(peer.displayName)
                                    .font(.caption)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                
                // Message Sending
                VStack(spacing: 10) {
                    Text("Send Message")
                        .font(.headline)
                    
                    HStack {
                        TextField("Message", text: $messageText)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Send") {
                            viewModel.sendMessage(messageText)
                            messageText = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(messageText.isEmpty)
                    }
                }
                
                // Received Messages
                if !viewModel.multipeerManager.receivedMessages.isEmpty {
                    VStack(spacing: 10) {
                        Text("Received")
                            .font(.headline)
                        
                        ScrollView {
                            LazyVStack(spacing: 5) {
                                ForEach(viewModel.multipeerManager.receivedMessages.suffix(3), id: \.self) { message in
                                    Text(message)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.blue.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                        .frame(maxHeight: 80)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Watch Settings View
struct WatchSettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Account Info
                VStack(spacing: 10) {
                    Text("Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Text("User:")
                        Spacer()
                        Text(viewModel.dataManagerInstance.currentUser?.username ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Premium:")
                        Spacer()
                        Text(viewModel.dataManagerInstance.isPremium ? "Yes" : "No")
                            .foregroundColor(viewModel.dataManagerInstance.isPremium ? .green : .orange)
                    }
                    .font(.caption)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Premium Actions
                if !viewModel.dataManagerInstance.isPremium {
                    VStack(spacing: 10) {
                        Button("Upgrade to Premium") {
                            viewModel.showPremiumUpgrade = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        Button("Enter Promo Code") {
                            viewModel.showPromoCode = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                
                // Features
                VStack(spacing: 10) {
                    Text("Features")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(viewModel.getPlatformSpecificFeatures(), id: \.self) { feature in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(feature)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Appearance
                VStack(spacing: 10) {
                    Text("Appearance")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Image(systemName: themeManager.themeMode.icon)
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text(themeManager.themeMode.rawValue)
                            .font(.caption)
                        Spacer()
                    }
                    
                    Picker("Theme", selection: $themeManager.themeMode) {
                        ForEach(ThemeManager.ThemeMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: themeManager.themeMode) { _, newValue in
                        themeManager.setThemeMode(newValue)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
}

// MARK: - Watch Premium Upgrade View
struct WatchPremiumUpgradeView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.linearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                
                Text("Upgrade to Premium")
                    .font(.headline)
                
                Text("Unlock all features")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    Text("• All 10 screens")
                    Text("• No ads")
                    Text("• CloudKit sync")
                    Text("• Multi-device")
                }
                .font(.caption2)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button("Purchase") {
                    viewModel.purchasePremium()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
        }
    }
}

// MARK: - Watch Promo Code View
struct WatchPromoCodeView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.linearGradient(
                        colors: [.green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("Enter Promo Code")
                    .font(.headline)
                
                TextField("Code", text: $viewModel.promoCodeInput)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                
                Button("Unlock Premium") {
                    viewModel.unlockWithPromoCode()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(viewModel.promoCodeInput.isEmpty)
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
        }
    }
}

// MARK: - Helper Views
struct WatchQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Text(title)
                    .font(.caption)
                
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WatchScreenButton: View {
    let number: Int
    let title: String
    let isPremium: Bool
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        Button(action: {
            if isPremium && !viewModel.dataManagerInstance.isPremium {
                viewModel.showPremiumUpgrade = true
            }
        }) {
            HStack {
                Image(systemName: "\(number).circle.fill")
                    .foregroundColor(isPremium ? .purple : .blue)
                    .font(.title3)
                
                Text("Screen \(number)")
                    .font(.caption)
                
                Spacer()
                
                if isPremium && !viewModel.dataManagerInstance.isPremium {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isPremium && !viewModel.dataManagerInstance.isPremium)
    }
} 