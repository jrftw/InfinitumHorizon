import SwiftUI

extension View {
    @ViewBuilder
    func conditionalSymbolEffect() -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.bounce, options: .repeating)
        } else {
            self
        }
    }
}

// MARK: - Screen 1 (Free)
struct Screen1View: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var messageText = ""
    @State private var showAd = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "1.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .conditionalSymbolEffect()
                    
                    Text("Screen 1 - Free")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Welcome to your first screen!")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Multipeer Connectivity
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
                    
                    HStack(spacing: 16) {
                        Button("Host Session") {
                            viewModel.startHosting()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .fontWeight(.medium)
                        
                        Button("Join Session") {
                            viewModel.startBrowsing()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .fontWeight(.medium)
                    }
                    
                    if !viewModel.multipeerManager.connectedPeers.isEmpty {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Connected Devices:")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.multipeerManager.connectedPeers, id: \.self) { peer in
                                    HStack {
                                        Image(systemName: "iphone")
                                            .foregroundStyle(.green)
                                        Text(peer.displayName)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
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
                    
                    if !viewModel.multipeerManager.receivedMessages.isEmpty {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "envelope.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Received Messages:")
                                    .font(.headline)
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
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(.regularMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    }
                                }
                            }
                            .frame(maxHeight: 120)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                
                // Cross-Device Control
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "iphone.gen3.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.linearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("Cross-Device Control")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 16) {
                        Button("Start Control") {
                            viewModel.startCrossDeviceControl()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .fontWeight(.medium)
                        
                        Button("Send Haptic") {
                            viewModel.sendHapticToWatch()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .fontWeight(.medium)
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Ad Display (for non-premium users)
                if !viewModel.dataManagerInstance.isPremium {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "megaphone.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            
                            Text("Advertisement")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Button("Show Ad") {
                            viewModel.showAd()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
        }
        .background(.ultraThinMaterial)
        .navigationTitle("Screen 1")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Screen 2 (Free)
struct Screen2View: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var sessionName = ""
    @State private var sessionId = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "2.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.linearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .conditionalSymbolEffect()
                    
                    Text("Screen 2 - Free")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Session Management")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Session Creation
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.linearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("Create New Session")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 12) {
                        TextField("Session name", text: $sessionName)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                        
                        Button("Create") {
                            viewModel.createSession(name: sessionName)
                            sessionName = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .fontWeight(.medium)
                        .disabled(sessionName.isEmpty)
                    }
                }
                
                // Session Joining
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "person.2.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.linearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("Join Existing Session")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 12) {
                        TextField("Session ID", text: $sessionId)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                        
                        Button("Join") {
                            viewModel.joinSession(sessionId)
                            sessionId = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .fontWeight(.medium)
                        .disabled(sessionId.isEmpty)
                    }
                }
                
                // Current Session Info
                if let currentSession = viewModel.dataManagerInstance.currentSession {
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            
                            Text("Current Session")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "person.circle.fill", label: "Name:", value: currentSession.name)
                            InfoRow(icon: "number.circle.fill", label: "ID:", value: currentSession.id, isSecondary: true)
                            InfoRow(icon: "person.3.circle.fill", label: "Participants:", value: "\(currentSession.participants.count)")
                            InfoRow(icon: "calendar.circle.fill", label: "Created:", value: currentSession.createdAt.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                // CloudKit Sync
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "icloud.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.linearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("CloudKit Sync")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Button("Sync to Cloud") {
                        viewModel.dataManagerInstance.syncToCloudKit()
                        viewModel.showAlert(message: "Syncing to CloudKit...")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .fontWeight(.medium)
                }
                
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
        }
        .background(.ultraThinMaterial)
        .navigationTitle("Screen 2")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Premium Screens (3-10)
struct PremiumScreenView: View {
    let screenNumber: Int
    @ObservedObject var viewModel: AppViewModel
    @State private var showPremiumUpgrade = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "\(screenNumber).circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.linearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .conditionalSymbolEffect()
                    
                    Text("Screen \(screenNumber) - Premium")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Exclusive premium content")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Premium Features
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "sparkles.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.linearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("Premium Features")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        FeatureCard(icon: "sparkles", text: "Advanced analytics", color: .purple)
                        FeatureCard(icon: "chart.line.uptrend.xyaxis", text: "Real-time data visualization", color: .blue)
                        FeatureCard(icon: "network", text: "Enhanced connectivity", color: .green)
                        FeatureCard(icon: "gear", text: "Custom configurations", color: .orange)
                        FeatureCard(icon: "lock.shield", text: "Enhanced security", color: .red)
                        FeatureCard(icon: "person.3.fill", text: "Team collaboration tools", color: .cyan)
                    }
                }
                
                // Screen-specific content
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "\(screenNumber).circle.fill")
                            .font(.title2)
                            .foregroundStyle(.linearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("Screen \(screenNumber) Exclusive")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(spacing: 16) {
                        switch screenNumber {
                        case 3:
                            PremiumContentCard(
                                title: "Advanced Analytics Dashboard",
                                description: "Comprehensive data visualization with real-time metrics, trend analysis, and predictive insights.",
                                icon: "chart.bar.fill",
                                color: .blue
                            )
                        case 4:
                            PremiumContentCard(
                                title: "AI-Powered Recommendations",
                                description: "Machine learning algorithms that provide personalized suggestions and optimize your workflow.",
                                icon: "brain.head.profile",
                                color: .purple
                            )
                        case 5:
                            PremiumContentCard(
                                title: "Advanced Security Suite",
                                description: "Enterprise-grade security features including end-to-end encryption and advanced threat detection.",
                                icon: "shield.checkered",
                                color: .green
                            )
                        case 6:
                            PremiumContentCard(
                                title: "Team Collaboration Hub",
                                description: "Real-time collaboration tools with shared workspaces, task management, and communication features.",
                                icon: "person.3.sequence.fill",
                                color: .orange
                            )
                        case 7:
                            PremiumContentCard(
                                title: "Custom Integrations",
                                description: "Connect with third-party services and create custom workflows tailored to your needs.",
                                icon: "link.circle.fill",
                                color: .cyan
                            )
                        case 8:
                            PremiumContentCard(
                                title: "Advanced Automation",
                                description: "Create complex automation workflows and schedule tasks to run automatically.",
                                icon: "gearshape.2.fill",
                                color: .indigo
                            )
                        case 9:
                            PremiumContentCard(
                                title: "Performance Monitoring",
                                description: "Monitor system performance, track resource usage, and optimize your device's efficiency.",
                                icon: "speedometer",
                                color: .red
                            )
                        case 10:
                            PremiumContentCard(
                                title: "Premium Support",
                                description: "Priority customer support with dedicated assistance and faster response times.",
                                icon: "headphones.circle.fill",
                                color: .pink
                            )
                        default:
                            PremiumContentCard(
                                title: "Premium Feature",
                                description: "Exclusive premium content and advanced functionality.",
                                icon: "star.fill",
                                color: .yellow
                            )
                        }
                    }
                }
                
                // Platform-specific premium features
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "iphone.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.linearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        Text("Platform Features")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(viewModel.getPlatformSpecificFeatures(), id: \.self) { feature in
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.title3)
                                
                                Text("Premium \(feature)")
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                
                // Upgrade prompt for non-premium users
                if !viewModel.dataManagerInstance.isPremium {
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "lock.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            
                            Text("🔒 Premium Content Locked")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                        }
                        
                        Text("Upgrade to premium to access this screen and all its features.")
                            .font(.body)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        
                        Button("Upgrade to Premium") {
                            showPremiumUpgrade = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .fontWeight(.medium)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
        }
        .background(.ultraThinMaterial)
        .navigationTitle("Screen \(screenNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPremiumUpgrade) {
            PremiumUpgradeView(viewModel: viewModel)
        }
    }
}

// MARK: - Helper Views
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    var isSecondary: Bool = false
    
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
                .font(isSecondary ? .caption : .body)
                .fontWeight(.medium)
                .foregroundStyle(isSecondary ? .secondary : .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct FeatureCard: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
            
            Text(text)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PremiumContentCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            Text(description)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
            
            HStack {
                Spacer()
                
                Button("Learn More") {
                    // Action for learning more
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .fontWeight(.medium)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
} 