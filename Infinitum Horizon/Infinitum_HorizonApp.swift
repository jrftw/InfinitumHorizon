//
//  Infinitum_HorizonApp.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//  Updated 7/21/2025 by @jrftw
//
//  Main application entry point for Infinitum Horizon
//  Handles cross-platform initialization, Firebase setup, SwiftData configuration,
//  and platform-specific view routing with fallback mechanisms.
//

import SwiftUI
import SwiftData
#if !os(visionOS)
import FirebaseCore
#endif

// MARK: - Main Application Structure
/// Main application struct that serves as the entry point for Infinitum Horizon
/// Manages cross-platform compatibility, data persistence, and view routing
@main
struct Infinitum_HorizonApp: App {
    // MARK: - State Objects
    /// Manages app-wide theme and color scheme preferences
    @StateObject private var themeManager = ThemeManager.shared
    /// Handles app version checking and update notifications
    @StateObject private var versionManager = AppVersionManager.shared
    
    // MARK: - Error Handling State
    /// Controls visibility of error alert dialogs
    @State private var showErrorAlert = false
    /// Stores the current error message for display
    @State private var errorMessage = ""
    /// Indicates if SwiftData initialization failed, triggering fallback mode
    @State private var hasDataError = false
    
    // MARK: - Initialization
    /// App initialization that handles Firebase setup and platform-specific configuration
    /// Firebase is excluded for visionOS due to compatibility issues
    init() {
        #if !os(visionOS)
        // Initialize Firebase if not already initialized
        // This ensures Firebase is ready before any Firebase-dependent services start
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            AppLogger.shared.info("Firebase initialized in app init")
        }
        #else
        // visionOS doesn't support Firebase, so we skip initialization
        // This prevents crashes and allows the app to run without Firebase features
        AppLogger.shared.info("visionOS: Firebase initialization skipped")
        #endif
    }
    
    // MARK: - SwiftData Configuration
    /// Shared ModelContainer that provides data persistence across the entire app
    /// Uses production schema with all models and includes fallback to in-memory storage
    var sharedModelContainer: ModelContainer = {
        // Production schema with all models
        do {
            AppLogger.shared.info("Creating production ModelContainer with full schema")
            // Define the complete data model schema including all entity types
            let schema = Schema([
                Item.self,           // Basic item model for testing
                User.self,           // User profile and authentication data
                Session.self,        // Session management and state
                DevicePosition.self  // Cross-device positioning data
            ])
            // Configure for persistent storage with save capabilities
            let config = ModelConfiguration(
                isStoredInMemoryOnly: false,  // Enable disk persistence
                allowsSave: true              // Allow data modifications
            )
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // FIXME: This error handling could be more specific about what failed
            // POTENTIAL ISSUE: Generic error handling may mask specific SwiftData issues
            AppLogger.shared.error("Failed to create production ModelContainer: \(error)")
            
            // Fallback to in-memory only when disk storage fails
            // This ensures the app can still run even with storage issues
            do {
                AppLogger.shared.info("Falling back to in-memory ModelContainer")
                let schema = Schema([
                    Item.self,
                    User.self,
                    Session.self,
                    DevicePosition.self
                ])
                // In-memory configuration for emergency fallback
                let config = ModelConfiguration(
                    isStoredInMemoryOnly: true,  // No disk persistence
                    allowsSave: false            // Read-only to prevent data corruption
                )
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                // SUGGESTION: Consider implementing a more graceful degradation strategy
                // that doesn't crash the app but shows a maintenance mode
                AppLogger.shared.fault("CRITICAL: Cannot create any ModelContainer")
                fatalError("SwiftData initialization failed: \(error.localizedDescription)")
            }
        }
    }()

    // MARK: - Main View Body
    /// Main scene configuration that handles platform-specific view routing
    /// Includes error handling overlay and theme management
    var body: some Scene {
        WindowGroup {
            Group {
                // Platform-specific view routing with fallback error handling
                // Each platform gets its own entry point while sharing the same data layer
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
                    // macOS uses direct entry without authentication container
                    // SUGGESTION: Consider adding authentication to macOS for consistency
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
                // Default fallback for unknown platforms
                if hasDataError {
                    FallbackView()
                } else {
                    AuthContainerView()
                }
                #endif
            }
            .preferredColorScheme(themeManager.colorScheme)
            .overlay {
                // Global error alert overlay for initialization issues
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
        // Ensure fullscreen layout on iOS for optimal user experience
        .windowResizability(.contentSize)
        #endif
    }
}

// MARK: - Authentication Container View
/// Manages authentication flow and data manager initialization for iOS
/// Acts as a coordinator between authentication state and main app views
struct AuthContainerView: View {
    // MARK: - Environment and State
    /// SwiftData model context for data operations
    @Environment(\.modelContext) private var modelContext
    /// Hybrid data manager that combines local and cloud storage
    @State private var dataManager: HybridDataManager?
    /// Firebase authentication manager for user login/logout
    @State private var authManager: FirebaseAuthManager?
    /// Loading state during initialization
    @State private var isLoading = true
    /// Indicates if all managers have been properly initialized
    @State private var isInitialized = false
    
    // MARK: - View Body
    /// Main view that routes between loading, authentication, and main app based on state
    var body: some View {
        Group {
            if isLoading || !isInitialized {
                // Show loading screen during initialization
                LoadingView()
            } else if let dataManager = dataManager,
                      let authManager = authManager,
                      authManager.isAuthenticated {
                // User is authenticated, show main app interface
                iOSEntryView(dataManager: dataManager)
            } else if let _ = dataManager,
                      let authManager = authManager {
                // Show authentication views for unauthenticated users
                AuthenticationView(authManager: authManager)
            } else {
                // Auth manager not ready, show loading
                LoadingView()
            }
        }
        .onAppear {
            setupDataManager()
        }
    }
    
    // MARK: - Initialization Methods
    /// Sets up the data manager and authentication manager with proper initialization order
    /// Uses async delays to ensure proper dependency initialization
    private func setupDataManager() {
        // Create hybrid data manager with Firebase support
        // This manager handles both local SwiftData and cloud Firebase operations
        let newDataManager = HybridDataManager(modelContext: modelContext)
        self.dataManager = newDataManager
        
        // Create Firebase auth manager with a slight delay to ensure proper initialization
        // SUGGESTION: Consider using a more robust initialization pattern with proper error handling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let newAuthManager = FirebaseAuthManager(dataManager: newDataManager)
            self.authManager = newAuthManager
            self.isLoading = false
            
            // Mark as initialized after a brief delay
            // This ensures all async operations complete before showing main UI
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.isInitialized = true
            }
        }
    }
}

// MARK: - Loading View
/// Displays an animated loading screen during app initialization
/// Provides visual feedback and branding while services start up
struct LoadingView: View {
    /// Controls the animation state of the app icon
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            // App Icon with animation
            // Uses infinity symbol to represent the "Infinitum" branding
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
/// Emergency fallback view when SwiftData is unavailable
/// Provides basic functionality and status information when core data layer fails
struct FallbackView: View {
    /// Simple counter to demonstrate basic functionality in fallback mode
    @State private var counter = 0
    
    var body: some View {
        VStack(spacing: 30) {
            // App Icon - Warning symbol to indicate fallback mode
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 100, weight: .medium))
                .foregroundStyle(.orange)
            
            // Title
            Text("Infinitum Horizon")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Subtitle indicating fallback mode
            Text("Fallback Mode")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            // Message explaining the situation
            Text("SwiftData is not available. Running in fallback mode.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Counter demonstration
            // SUGGESTION: This could be replaced with more useful fallback functionality
            VStack(spacing: 10) {
                Text("Counter: \(counter)")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Button("Increment") {
                    counter += 1
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Status indicators showing what's working and what's not
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
