import SwiftUI

// MARK: - Main Cross-Device Control View
struct CrossDeviceControlView: View {
    @ObservedObject var controlManager = CrossDeviceControlManager.shared
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedDevice: ConnectedDevice?
    @State private var showDeviceDetail = false
    @State private var showSetupInstructions = false
    @State private var selectedDeviceType: DeviceType?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Premium Check
                    
                    // Premium Check
                    let isPremium = viewModel.dataManagerInstance.isPremium
                    
                    if !isPremium {
                        PremiumRequiredView(viewModel: viewModel)
                    } else {
                        // Connection Status
                        ConnectionStatusView()
                        
                        // Setup Instructions
                        SetupInstructionsView(
                            showSetupInstructions: $showSetupInstructions,
                            selectedDeviceType: $selectedDeviceType
                        )
                        
                        // Connected Devices
                        ConnectedDevicesView(selectedDevice: $selectedDevice, showDeviceDetail: $showDeviceDetail)
                        
                        // Quick Actions
                        QuickActionsView()
                        
                        // Command History
                        CommandHistoryView()
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Cross-Device Control")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.showPremiumUpgrade) {
                PremiumUpgradeView(viewModel: viewModel)
            }
            .sheet(isPresented: $showDeviceDetail) {
                if let device = selectedDevice {
                    DeviceDetailView(device: device)
                }
            }
            .sheet(isPresented: $showSetupInstructions) {
                if let deviceType = selectedDeviceType {
                    DeviceSetupInstructionsView(deviceType: deviceType)
                }
            }
        }
        .onAppear {
            // Refresh premium status
        }
    }
}

// MARK: - Premium Required View
struct PremiumRequiredView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            // Premium Icon
            Image(systemName: "crown.circle.fill")
                .font(.system(size: 80, weight: .medium))
                .foregroundStyle(.linearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            // Title
            VStack(spacing: 16) {
                Text("Premium Feature")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Cross-Device Control requires a premium subscription")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Features List
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "sparkles.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    
                    Text("What you'll get:")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                VStack(spacing: 16) {
                    PremiumFeatureRow(icon: "iphone.gen3", title: "Control iPhone/iPad", description: "Launch apps, open URLs, send messages")
                    PremiumFeatureRow(icon: "macbook", title: "Control Mac", description: "Run scripts, open apps, execute commands")
                    PremiumFeatureRow(icon: "applewatch", title: "Control Apple Watch", description: "Send haptics, start workouts, notifications")
                    PremiumFeatureRow(icon: "visionpro", title: "Control Vision Pro", description: "Change layouts, immersive experiences")
                    PremiumFeatureRow(icon: "appletv", title: "Control Apple TV", description: "Launch apps, control playback")
                }
            }
            
            // Upgrade Button
            Button("Upgrade to Premium") {
                viewModel.showPremiumUpgrade = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .fontWeight(.semibold)
            
            // Learn More
            Button("Learn More") {
                // Show detailed feature comparison
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .fontWeight(.medium)
        }
        .padding(32)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Premium Feature Row
struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Setup Instructions View
struct SetupInstructionsView: View {
    @Binding var showSetupInstructions: Bool
    @Binding var selectedDeviceType: DeviceType?
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("Setup Instructions")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                DeviceSetupCard(
                    deviceType: .iPhone,
                    icon: "iphone",
                    title: "iPhone/iPad",
                    color: .blue
                ) {
                    selectedDeviceType = .iPhone
                    showSetupInstructions = true
                }
                
                DeviceSetupCard(
                    deviceType: .Mac,
                    icon: "macbook",
                    title: "Mac",
                    color: .orange
                ) {
                    selectedDeviceType = .Mac
                    showSetupInstructions = true
                }
                
                DeviceSetupCard(
                    deviceType: .AppleWatch,
                    icon: "applewatch",
                    title: "Apple Watch",
                    color: .green
                ) {
                    selectedDeviceType = .AppleWatch
                    showSetupInstructions = true
                }
                
                DeviceSetupCard(
                    deviceType: .VisionPro,
                    icon: "visionpro",
                    title: "Vision Pro",
                    color: .cyan
                ) {
                    selectedDeviceType = .VisionPro
                    showSetupInstructions = true
                }
            }
        }
    }
}

// MARK: - Device Setup Card
struct DeviceSetupCard: View {
    let deviceType: DeviceType
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                Text("Setup Guide")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Connection Status View
struct ConnectionStatusView: View {
    @ObservedObject var controlManager = CrossDeviceControlManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("Connection Status")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: controlManager.isHosting ? "antenna.radiowaves.left.and.right.circle.fill" : "antenna.radiowaves.left.and.right.circle")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(controlManager.isHosting ? .green : .gray)
                    
                    Text("Host")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                
                VStack(spacing: 12) {
                    Image(systemName: controlManager.isBrowsing ? "antenna.radiowaves.left.and.right.circle.fill" : "antenna.radiowaves.left.and.right.circle")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(controlManager.isBrowsing ? .blue : .gray)
                    
                    Text("Browse")
                        .font(.headline)
                        .fontWeight(.medium)
                }
            }
            
            HStack(spacing: 16) {
                Button("Start Hosting") {
                    controlManager.startHosting()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .fontWeight(.medium)
                .disabled(controlManager.isHosting)
                
                Button("Start Browsing") {
                    controlManager.startBrowsing()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .fontWeight(.medium)
                .disabled(controlManager.isBrowsing)
            }
            
            if controlManager.isHosting || controlManager.isBrowsing {
                Button("Disconnect") {
                    controlManager.disconnect()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .fontWeight(.medium)
                .foregroundColor(.red)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Connected Devices View
struct ConnectedDevicesView: View {
    @ObservedObject var controlManager = CrossDeviceControlManager.shared
    @Binding var selectedDevice: ConnectedDevice?
    @Binding var showDeviceDetail: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "iphone.gen3.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.linearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("Connected Devices")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(controlManager.connectedDevices.count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            if controlManager.connectedDevices.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "iphone.gen3.circle")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(.gray)
                    
                    Text("No devices connected")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text("Start hosting or browsing to discover nearby devices")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(controlManager.connectedDevices) { device in
                        DeviceRowView(device: device) {
                            selectedDevice = device
                            showDeviceDetail = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Device Row View
struct DeviceRowView: View {
    let device: ConnectedDevice
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: deviceIcon(for: device.deviceType))
                    .font(.title2)
                    .foregroundStyle(deviceColor(for: device.deviceType))
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.peerId.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(device.deviceType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(device.isReachable ? .green : .red)
                        .frame(width: 8, height: 8)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func deviceIcon(for deviceType: DeviceType) -> String {
        switch deviceType {
        case .iPhone: return "iphone"
        case .iPad: return "ipad"
        case .Mac: return "macbook"
        case .AppleWatch: return "applewatch"
        case .VisionPro: return "visionpro"
        case .AppleTV: return "appletv"
        }
    }
    
    private func deviceColor(for deviceType: DeviceType) -> Color {
        switch deviceType {
        case .iPhone: return .blue
        case .iPad: return .purple
        case .Mac: return .orange
        case .AppleWatch: return .green
        case .VisionPro: return .cyan
        case .AppleTV: return .red
        }
    }
}

// MARK: - Quick Actions View
struct QuickActionsView: View {
    @ObservedObject var controlManager = CrossDeviceControlManager.shared
    @State private var selectedURL = ""
    @State private var selectedAppName = ""
    @State private var selectedScript = ""
    
    var body: some View {
        VStack(spacing: 20) {
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
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ControlQuickActionCard(
                    icon: "safari",
                    title: "Open URL",
                    color: .blue
                ) {
                    // Show URL input
                }
                
                ControlQuickActionCard(
                    icon: "app.badge",
                    title: "Launch App",
                    color: .green
                ) {
                    // Show app selection
                }
                
                ControlQuickActionCard(
                    icon: "heart.circle",
                    title: "Watch Haptic",
                    color: .pink
                ) {
                    controlManager.sendHapticToWatch(.notification)
                }
                
                ControlQuickActionCard(
                    icon: "figure.run",
                    title: "Start Workout",
                    color: .orange
                ) {
                    controlManager.startWorkoutOnWatch(workoutType: "Running") { success in
                        // Workout started
                    }
                }
                
                ControlQuickActionCard(
                    icon: "terminal",
                    title: "AppleScript",
                    color: .purple
                ) {
                    // Show script input
                }
                
                ControlQuickActionCard(
                    icon: "display",
                    title: "Change Layout",
                    color: .cyan
                ) {
                    controlManager.changeVisionProLayout(.immersive) { success in
                        // Layout changed
                    }
                }
            }
        }
    }
}

// MARK: - Control Quick Action Card
struct ControlQuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Command History View
struct CommandHistoryView: View {
    @ObservedObject var controlManager = CrossDeviceControlManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "clock.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.linearGradient(
                        colors: [.gray, .secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("Command History")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !controlManager.receivedCommands.isEmpty {
                    Button("Clear") {
                        controlManager.receivedCommands.removeAll()
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.red)
                }
            }
            
            if controlManager.receivedCommands.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.circle")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(.gray)
                    
                    Text("No commands received")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(controlManager.receivedCommands.prefix(10)) { command in
                        CommandRowView(command: command)
                    }
                }
            }
        }
    }
}

// MARK: - Command Row View
struct CommandRowView: View {
    let command: DeviceCommand
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: commandIcon(for: command.type))
                .font(.title3)
                .foregroundStyle(commandColor(for: command.type))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(command.type.rawValue.capitalized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("To: \(command.targetDevice)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Text(command.timestamp.formatted(date: .omitted, time: .standard))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func commandIcon(for commandType: CommandType) -> String {
        switch commandType {
        case .launchApp: return "app.badge"
        case .openURL: return "safari"
        case .watchHaptic: return "heart.circle"
        case .startWorkout: return "figure.run"
        case .stopWorkout: return "stop.circle"
        case .executeScript: return "terminal"
        case .openMacApp: return "macbook"
        case .changeLayout: return "display"
        case .controlImmersive: return "visionpro"
        case .updateDashboard: return "chart.bar"
        }
    }
    
    private func commandColor(for commandType: CommandType) -> Color {
        switch commandType {
        case .launchApp: return .green
        case .openURL: return .blue
        case .watchHaptic: return .pink
        case .startWorkout: return .orange
        case .stopWorkout: return .red
        case .executeScript: return .purple
        case .openMacApp: return .orange
        case .changeLayout: return .cyan
        case .controlImmersive: return .indigo
        case .updateDashboard: return .mint
        }
    }
}

// MARK: - Device Detail View
struct DeviceDetailView: View {
    let device: ConnectedDevice
    @ObservedObject var controlManager = CrossDeviceControlManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Device Info
                    DeviceInfoSection(device: device)
                    
                    // Control Actions
                    DeviceControlSection(device: device)
                    
                    // Status
                    DeviceStatusSection(device: device)
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
            }
            .background(.ultraThinMaterial)
            .navigationTitle(device.peerId.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - Device Info Section
struct DeviceInfoSection: View {
    let device: ConnectedDevice
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                Text("Device Information")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 16) {
                ControlInfoRow(icon: "iphone", label: "Name:", value: device.peerId.displayName)
                ControlInfoRow(icon: "gear", label: "Type:", value: device.deviceType.rawValue)
                ControlInfoRow(icon: "wifi", label: "Status:", value: device.isReachable ? "Connected" : "Disconnected")
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Device Control Section
struct DeviceControlSection: View {
    let device: ConnectedDevice
    @ObservedObject var controlManager = CrossDeviceControlManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                
                Text("Control Actions")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                DeviceControlCard(
                    icon: "safari",
                    title: "Open URL",
                    color: .blue
                ) {
                    // Implement URL opening
                }
                
                DeviceControlCard(
                    icon: "app.badge",
                    title: "Launch App",
                    color: .green
                ) {
                    // Implement app launching
                }
                
                if device.deviceType == .AppleWatch {
                    DeviceControlCard(
                        icon: "heart.circle",
                        title: "Send Haptic",
                        color: .pink
                    ) {
                        controlManager.sendHapticToWatch(.notification)
                    }
                }
                
                if device.deviceType == .Mac {
                    DeviceControlCard(
                        icon: "terminal",
                        title: "Run Script",
                        color: .purple
                    ) {
                        // Implement script execution
                    }
                }
                
                if device.deviceType == .VisionPro {
                    DeviceControlCard(
                        icon: "display",
                        title: "Change Layout",
                        color: .cyan
                    ) {
                        controlManager.changeVisionProLayout(.immersive) { _ in }
                    }
                }
            }
        }
    }
}

// MARK: - Device Control Card
struct DeviceControlCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Device Status Section
struct DeviceStatusSection: View {
    let device: ConnectedDevice
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                Text("Status")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    Circle()
                        .fill(device.isReachable ? .green : .red)
                        .frame(width: 16, height: 16)
                    
                    Text("Connection")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 8) {
                    Image(systemName: "wifi")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    
                    Text("Network")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 8) {
                    Image(systemName: "battery.100")
                        .font(.title3)
                        .foregroundStyle(.green)
                    
                    Text("Battery")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Control Info Row
struct ControlInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(label)
                .font(.body)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
} 

// MARK: - Device Setup Instructions View
struct DeviceSetupInstructionsView: View {
    let deviceType: DeviceType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Device Icon and Title
                    VStack(spacing: 16) {
                        Image(systemName: deviceIcon)
                            .font(.system(size: 80, weight: .medium))
                            .foregroundStyle(deviceColor)
                        
                        Text("\(deviceTitle) Setup")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                    .padding(.top, 20)
                    
                    // Setup Steps
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "list.number.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            
                            Text("Setup Steps")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 16) {
                            ForEach(setupSteps.indices, id: \.self) { index in
                                SetupStepRow(
                                    stepNumber: index + 1,
                                    title: setupSteps[index].title,
                                    description: setupSteps[index].description,
                                    icon: setupSteps[index].icon
                                )
                            }
                        }
                    }
                    
                    // Requirements
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                            
                            Text("Requirements")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(requirements, id: \.self) { requirement in
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.green)
                                    
                                    Text(requirement)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    
                    // Troubleshooting
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "wrench.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            
                            Text("Troubleshooting")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(troubleshootingTips, id: \.self) { tip in
                                HStack(spacing: 12) {
                                    Image(systemName: "lightbulb.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.orange)
                                    
                                    Text(tip)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Setup Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private var deviceIcon: String {
        switch deviceType {
        case .iPhone: return "iphone"
        case .iPad: return "ipad"
        case .Mac: return "macbook"
        case .AppleWatch: return "applewatch"
        case .VisionPro: return "visionpro"
        case .AppleTV: return "appletv"
        }
    }
    
    private var deviceColor: Color {
        switch deviceType {
        case .iPhone: return .blue
        case .iPad: return .purple
        case .Mac: return .orange
        case .AppleWatch: return .green
        case .VisionPro: return .cyan
        case .AppleTV: return .red
        }
    }
    
    private var deviceTitle: String {
        switch deviceType {
        case .iPhone: return "iPhone/iPad"
        case .iPad: return "iPhone/iPad"
        case .Mac: return "Mac"
        case .AppleWatch: return "Apple Watch"
        case .VisionPro: return "Vision Pro"
        case .AppleTV: return "Apple TV"
        }
    }
    
    private var setupSteps: [(title: String, description: String, icon: String)] {
        switch deviceType {
        case .iPhone, .iPad:
            return [
                ("Install App", "Download Infinitum Horizon from the App Store on your iPhone or iPad", "app.badge"),
                ("Open App", "Launch the app and navigate to Cross-Device Control", "play.circle"),
                ("Start Hosting", "Tap 'Start Hosting' to make your device discoverable", "antenna.radiowaves.left.and.right"),
                ("Grant Permissions", "Allow notifications and local network access when prompted", "checkmark.shield"),
                ("Wait for Connection", "Your device will appear in the Vision Pro's device list", "wifi")
            ]
        case .Mac:
            return [
                ("Install App", "Download Infinitum Horizon from the Mac App Store", "app.badge"),
                ("Open App", "Launch the app and go to Cross-Device Control", "play.circle"),
                ("Start Hosting", "Click 'Start Hosting' to make your Mac discoverable", "antenna.radiowaves.left.and.right"),
                ("System Preferences", "Go to System Preferences > Security & Privacy > Privacy > Local Network", "gear"),
                ("Enable Local Network", "Check the box next to Infinitum Horizon", "checkmark.shield"),
                ("Wait for Connection", "Your Mac will appear in the Vision Pro's device list", "wifi")
            ]
        case .AppleWatch:
            return [
                ("Install App", "Install Infinitum Horizon on your Apple Watch from the Watch app", "app.badge"),
                ("Open App", "Launch the app on your Apple Watch", "play.circle"),
                ("Start Hosting", "Tap 'Start Hosting' to make your watch discoverable", "antenna.radiowaves.left.and.right"),
                ("Keep App Open", "Keep the app running in the foreground", "eye"),
                ("Wait for Connection", "Your watch will appear in the Vision Pro's device list", "wifi")
            ]
        case .VisionPro:
            return [
                ("Open App", "Launch Infinitum Horizon on your Vision Pro", "play.circle"),
                ("Navigate to Control", "Go to Cross-Device Control section", "gamecontroller"),
                ("Start Browsing", "Tap 'Start Browsing' to discover nearby devices", "antenna.radiowaves.left.and.right"),
                ("Select Device", "Tap on a device in the list to connect", "iphone"),
                ("Grant Permissions", "Allow the connection when prompted", "checkmark.shield"),
                ("Start Controlling", "Use the quick actions to control your device", "bolt")
            ]
        case .AppleTV:
            return [
                ("Install App", "Download Infinitum Horizon from the App Store on Apple TV", "app.badge"),
                ("Open App", "Launch the app using the Siri Remote", "play.circle"),
                ("Start Hosting", "Select 'Start Hosting' to make your Apple TV discoverable", "antenna.radiowaves.left.and.right"),
                ("Keep App Active", "Keep the app running (don't go to home screen)", "eye"),
                ("Wait for Connection", "Your Apple TV will appear in the Vision Pro's device list", "wifi")
            ]
        }
    }
    
    private var requirements: [String] {
        switch deviceType {
        case .iPhone, .iPad:
            return [
                "iOS 15.0 or later",
                "Infinitum Horizon app installed",
                "Premium subscription",
                "Same Wi-Fi network as Vision Pro",
                "Bluetooth enabled"
            ]
        case .Mac:
            return [
                "macOS 12.0 or later",
                "Infinitum Horizon app installed",
                "Premium subscription",
                "Same Wi-Fi network as Vision Pro",
                "Local network permissions granted"
            ]
        case .AppleWatch:
            return [
                "watchOS 8.0 or later",
                "Infinitum Horizon app installed",
                "Premium subscription",
                "Paired with iPhone on same network",
                "App kept in foreground"
            ]
        case .VisionPro:
            return [
                "visionOS 1.0 or later",
                "Infinitum Horizon app installed",
                "Premium subscription",
                "Same Wi-Fi network as target devices",
                "Bluetooth enabled"
            ]
        case .AppleTV:
            return [
                "tvOS 15.0 or later",
                "Infinitum Horizon app installed",
                "Premium subscription",
                "Same Wi-Fi network as Vision Pro",
                "App kept active"
            ]
        }
    }
    
    private var troubleshootingTips: [String] {
        switch deviceType {
        case .iPhone, .iPad:
            return [
                "Make sure both devices are on the same Wi-Fi network",
                "Check that Bluetooth is enabled on both devices",
                "Restart the app if connection fails",
                "Ensure the app has notification permissions",
                "Try moving devices closer together"
            ]
        case .Mac:
            return [
                "Check System Preferences > Security & Privacy > Privacy > Local Network",
                "Ensure both devices are on the same Wi-Fi network",
                "Restart the app if connection fails",
                "Check firewall settings",
                "Try disabling VPN if active"
            ]
        case .AppleWatch:
            return [
                "Keep the app running in the foreground",
                "Ensure your iPhone is on the same network",
                "Check that the watch is unlocked",
                "Restart the app if connection fails",
                "Try restarting both watch and iPhone"
            ]
        case .VisionPro:
            return [
                "Make sure you're browsing for devices",
                "Check that target devices are hosting",
                "Ensure all devices are on the same network",
                "Try refreshing the device list",
                "Restart the app if no devices appear"
            ]
        case .AppleTV:
            return [
                "Keep the app active (don't go to home screen)",
                "Ensure both devices are on the same network",
                "Check that the Apple TV is not in sleep mode",
                "Restart the app if connection fails",
                "Try restarting the Apple TV"
            ]
        }
    }
}

// MARK: - Setup Step Row
struct SetupStepRow: View {
    let stepNumber: Int
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Step Number
            ZStack {
                Circle()
                    .fill(.blue)
                    .frame(width: 32, height: 32)
                
                Text("\(stepNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
} 