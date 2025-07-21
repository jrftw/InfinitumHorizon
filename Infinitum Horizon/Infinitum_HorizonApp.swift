//
//  Infinitum_HorizonApp.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//

import SwiftUI
import SwiftData
#if !os(visionOS)
import FirebaseCore
#endif



@main
struct Infinitum_HorizonApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var versionManager = AppVersionManager.shared
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var hasDataError = false
    
    // Initialize Firebase first (except for visionOS)
    init() {
        #if !os(visionOS)
        // Initialize Firebase if not already initialized
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            AppLogger.shared.info("Firebase initialized in app init")
        }
        #else
        AppLogger.shared.info("visionOS: Firebase initialization skipped")
        #endif
    }
    
    var sharedModelContainer: ModelContainer = {
        // Production schema with all models
        do {
            AppLogger.shared.info("Creating production ModelContainer with full schema")
            let schema = Schema([
                Item.self,
                User.self,
                Session.self,
                DevicePosition.self
            ])
            let config = ModelConfiguration(
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            AppLogger.shared.error("Failed to create production ModelContainer: \(error)")
            
            // Fallback to in-memory only
            do {
                AppLogger.shared.info("Falling back to in-memory ModelContainer")
                let schema = Schema([
                    Item.self,
                    User.self,
                    Session.self,
                    DevicePosition.self
                ])
                let config = ModelConfiguration(
                    isStoredInMemoryOnly: true,
                    allowsSave: false
                )
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                AppLogger.shared.fault("CRITICAL: Cannot create any ModelContainer")
                fatalError("SwiftData initialization failed: \(error.localizedDescription)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                // Ensure fullscreen layout on all devices
                #if os(iOS)
                if hasDataError {
                    FallbackView()
                } else {
                    AuthContainerView()
                }
                #elseif os(macOS)
                if hasDataError {
                    FallbackView()
                } else {
                    macOSEntryView(dataManager: HybridDataManager(modelContext: sharedModelContainer.mainContext))
                }
                #elseif os(tvOS)
                if hasDataError {
                    FallbackView()
                } else {
                    tvOSEntryView(dataManager: HybridDataManager(modelContext: sharedModelContainer.mainContext))
                }
                #elseif os(watchOS)
                if hasDataError {
                    FallbackView()
                } else {
                    WatchOSEntryView(dataManager: HybridDataManager(modelContext: sharedModelContainer.mainContext))
                }
                #elseif os(visionOS)
                if hasDataError {
                    FallbackView()
                } else {
                    VisionOSEntryView(dataManager: HybridDataManager(modelContext: sharedModelContainer.mainContext))
                }
                #else
                if hasDataError {
                    FallbackView()
                } else {
                    AuthContainerView()
                }
                #endif
            }
            .preferredColorScheme(themeManager.colorScheme)
            .overlay {
                if showErrorAlert {
                    CustomAlertView(
                        title: "Initialization Error",
                        message: errorMessage,
                        dismissAction: {
                            showErrorAlert = false
                        }
                    )
                }
            }
        }
        .modelContainer(sharedModelContainer)
        #if os(iOS)
        // Ensure fullscreen layout on iOS
        .windowResizability(.contentSize)
        #endif
    }
}

// MARK: - Auth Container View
struct AuthContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataManager: HybridDataManager?
    @State private var authManager: FirebaseAuthManager?
    @State private var isLoading = true
    @State private var isInitialized = false
    
    var body: some View {
        Group {
            if isLoading || !isInitialized {
                LoadingView()
            } else if let dataManager = dataManager,
                      let authManager = authManager,
                      authManager.isAuthenticated {
                // User is authenticated, show main app
                iOSEntryView(dataManager: dataManager)
            } else if let _ = dataManager,
                      let authManager = authManager {
                // Show authentication views
                AuthenticationView(authManager: authManager)
            } else {
                // Auth manager not ready
                LoadingView()
            }
        }
        .onAppear {
            setupDataManager()
        }
    }
    
    private func setupDataManager() {
        // Create hybrid data manager with Firebase support
        let newDataManager = HybridDataManager(modelContext: modelContext)
        self.dataManager = newDataManager
        
        // Create Firebase auth manager with a slight delay to ensure proper initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let newAuthManager = FirebaseAuthManager(dataManager: newDataManager)
            self.authManager = newAuthManager
            self.isLoading = false
            
            // Mark as initialized after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.isInitialized = true
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            // App Icon with animation
            Image(systemName: "infinity.circle.fill")
                .font(.system(size: 100, weight: .medium))
                .foregroundStyle(.linearGradient(
                    colors: [.orange, .red, .yellow],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            
            // Title
            Text("Infinitum Horizon")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Loading indicator
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            // Status text
            Text("Initializing...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Fallback View
struct FallbackView: View {
    @State private var counter = 0
    
    var body: some View {
        VStack(spacing: 30) {
            // App Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 100, weight: .medium))
                .foregroundStyle(.orange)
            
            // Title
            Text("Infinitum Horizon")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Subtitle
            Text("Fallback Mode")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            // Message
            Text("SwiftData is not available. Running in fallback mode.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Counter
            VStack(spacing: 10) {
                Text("Counter: \(counter)")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Button("Increment") {
                    counter += 1
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Status
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("App Launched Successfully")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("SwiftData Not Available")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("No Crashes")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
        }
        .padding()
    }
}
