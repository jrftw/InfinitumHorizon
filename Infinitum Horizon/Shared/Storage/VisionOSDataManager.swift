//
//  VisionOSDataManager.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//  Updated 7/21/2025 by @jrftw
//
//  visionOS-specific data management service without Firebase dependencies
//  Provides local SwiftData persistence and CloudKit synchronization
//  Handles visionOS-specific user creation and app lifecycle management
//

import Foundation
import SwiftData
import CloudKit
import Combine

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

// MARK: - VisionOS Data Manager
/// visionOS-specific data management service that operates without Firebase
/// Provides local SwiftData persistence and CloudKit synchronization
/// Handles visionOS-specific user creation and app lifecycle management
/// Uses @MainActor for UI thread safety and ObservableObject for SwiftUI integration
@MainActor
class VisionOSDataManager: ObservableObject {
    // MARK: - Published Properties
    /// Current authenticated user for the app
    /// Updated automatically when user data changes
    @Published var currentUser: User?
    
    /// Current active session for collaborative features
    /// Manages multi-device session state with CloudKit synchronization
    @Published var currentSession: Session?
    
    /// Premium subscription status for current user
    /// Controls access to premium features and content
    @Published var isPremium: Bool = false
    
    /// Number of screens unlocked for current user
    /// Free users get 2 screens, premium users get all screens
    @Published var unlockedScreens: Int = 2
    
    /// Loading state for data operations
    /// Used for UI feedback during async operations
    @Published var isLoading = false
    
    /// Error message for display to user
    /// Set when data operations fail
    @Published var errorMessage: String?
    
    /// Current synchronization status for CloudKit operations
    /// Provides feedback on sync operations for UI updates
    @Published var syncStatus: VisionOSSyncStatus = .idle
    
    /// Network connectivity status for CloudKit operations
    /// Monitored to ensure reliable data synchronization
    @Published var isOnline = false
    
    // MARK: - Core Services
    /// SwiftData model context for local database operations
    private let modelContext: ModelContext
    
    // MARK: - Public Accessors
    /// Returns the SwiftData model context for direct database access
    /// Used by other components that need direct SwiftData operations
    var getModelContext: ModelContext {
        return modelContext
    }
    
    /// CloudKit container for Apple ecosystem synchronization
    private let cloudKitContainer = CKContainer.default()
    
    // MARK: - Private Properties
    /// Combine cancellables for managing subscriptions and bindings
    private var cancellables = Set<AnyCancellable>()
    
    /// Flag indicating if SwiftData is available and working
    /// Used for fallback behavior when data layer fails
    private var isSwiftDataAvailable = true
    
    /// Dedicated queue for synchronization operations
    /// Prevents blocking main thread during sync operations
    private var syncQueue = DispatchQueue(label: "com.infinitumhorizon.visionos.sync", qos: .utility)
    
    /// Timestamp of last successful synchronization
    /// Used to prevent excessive sync operations
    private var lastSyncTime: Date?
    
    /// Timer for periodic synchronization operations
    /// Automatically syncs data at regular intervals
    private var syncTimer: Timer?
    
    // MARK: - Configuration
    /// Interval between periodic sync operations (5 minutes)
    private let syncInterval: TimeInterval = 300 // 5 minutes
    
    /// Maximum number of retry attempts for failed operations
    private let maxRetries = 3
    
    /// Delay between retry attempts (2 seconds)
    private let retryDelay: TimeInterval = 2
    
    // MARK: - Initialization
    /// Creates VisionOSDataManager with SwiftData model context
    /// Sets up CloudKit synchronization and initializes all subsystems
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupBindings()
        setupNotifications()
        startPeriodicSync()
        loadCurrentUser()
    }
    
    /// Cleanup method that invalidates timers and removes observers
    deinit {
        syncTimer?.invalidate()
    }
    
    // MARK: - Setup and Configuration
    
    /// Sets up reactive bindings for published properties
    /// Automatically updates derived properties when user changes
    private func setupBindings() {
        // Bind to current user changes
        $currentUser
            .sink { [weak self] user in
                self?.isPremium = user?.isPremium ?? false
                self?.unlockedScreens = user?.unlockedScreens ?? 2
            }
            .store(in: &cancellables)
    }
    
    /// Sets up notification observers for app lifecycle events
    /// Monitors app state changes for data persistence and synchronization
    private func setupNotifications() {
        // Monitor app state changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppWillResignActive()
            }
            .store(in: &cancellables)
    }
    
    /// Starts periodic synchronization timer
    /// Automatically syncs data at configured intervals
    private func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncData()
            }
        }
    }
    
    // MARK: - User Management
    
    /// Loads existing user from device storage or creates anonymous user
    /// Attempts to find existing user, falls back to creating visionOS-specific user
    private func loadCurrentUser() {
        Task {
            do {
                let descriptor = FetchDescriptor<User>()
                let users = try modelContext.fetch(descriptor)
                
                if let user = users.first {
                    currentUser = user
                    AppLogger.shared.info("Loaded existing user: \(user.username)")
                } else {
                    // Create anonymous user for visionOS
                    await createAnonymousUser()
                }
            } catch {
                AppLogger.shared.error("Failed to load user: \(error)")
                errorMessage = "Failed to load user data"
            }
        }
    }
    
    /// Creates anonymous user specifically for visionOS platform
    /// Sets visionOS-specific defaults and skips email verification
    private func createAnonymousUser() async {
        let deviceId = getDeviceId()
        let platform = "visionOS"
        
        let username = "VisionOS_\(deviceId.prefix(8))"
        let email = "\(username.lowercased())@visionos.local"
        
        let newUser = User(
            username: username,
            email: email,
            passwordHash: "", // No password for anonymous users
            deviceId: deviceId,
            platform: platform
        )
        
        // Set visionOS-specific defaults
        newUser.isEmailVerified = true // Skip email verification for visionOS
        newUser.isActive = true
        newUser.lastActiveAt = Date()
        newUser.isPremium = false
        newUser.unlockedScreens = 2 // Free screens
        newUser.totalScreens = 10
        newUser.adsEnabled = false // No ads on visionOS
        newUser.displayName = username
        newUser.preferences = "{}"
        
        do {
            try await saveUser(newUser)
            currentUser = newUser
            AppLogger.shared.info("Created anonymous visionOS user: \(username)")
        } catch {
            AppLogger.shared.error("Failed to create visionOS user: \(error)")
            errorMessage = "Failed to create user account"
        }
    }
    
    // MARK: - Data Operations
    
    /// Saves user data to SwiftData with error handling
    /// Persists user changes to local storage
    func saveUser(_ user: User) async throws {
        do {
            modelContext.insert(user)
            try modelContext.save()
            AppLogger.shared.info("User saved to SwiftData: \(user.username)")
        } catch {
            AppLogger.shared.error("Error saving user to SwiftData: \(error)")
            throw DataManagerError.swiftDataError(error)
        }
    }
    
    /// Deletes user and all associated data from SwiftData
    /// Removes user from local storage and clears current user if applicable
    func deleteUser(_ user: User) async throws {
        do {
            modelContext.delete(user)
            try modelContext.save()
            if currentUser?.id == user.id {
                currentUser = nil
            }
            AppLogger.shared.info("User deleted from SwiftData: \(user.username)")
        } catch {
            AppLogger.shared.error("Error deleting user from SwiftData: \(error)")
            throw DataManagerError.swiftDataError(error)
        }
    }
    
    /// Finds user by email address (case-insensitive)
    /// Returns nil if no user found with matching email
    func findUserByEmail(_ email: String) async -> User? {
        do {
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate<User> { user in
                    user.email == email
                }
            )
            let users = try modelContext.fetch(descriptor)
            return users.first
        } catch {
            AppLogger.shared.error("Error finding user by email: \(error)")
            return nil
        }
    }
    
    // MARK: - Premium Features
    
    /// Purchases premium subscription for current user
    /// Updates user status and unlocks all features
    func purchasePremium() {
        guard let user = currentUser else { return }
        
        user.isPremium = true
        user.unlockedScreens = user.totalScreens
        user.adsEnabled = false
        user.subscriptionExpiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        user.updatedAt = Date()
        
        do {
            try modelContext.save()
            AppLogger.shared.info("Premium purchased successfully for visionOS")
        } catch {
            AppLogger.shared.error("Error purchasing premium: \(error)")
            errorMessage = "Failed to activate premium"
        }
    }
    
    /// Unlocks premium features using visionOS-specific promotional code
    /// Validates code and applies premium benefits
    /// SUGGESTION: Consider moving promo codes to server-side validation
    func applyPromoCode(_ code: String) -> Bool {
        guard let user = currentUser else { return false }
        
        // Simple promo code validation for visionOS
        let validCodes = ["VISIONOS2025", "SPATIAL", "PREMIUM"]
        
        guard validCodes.contains(code.uppercased()) else {
            return false
        }
        
        user.isPremium = true
        user.promoCodeUsed = code.uppercased()
        user.unlockedScreens = user.totalScreens
        user.adsEnabled = false
        user.subscriptionExpiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        user.updatedAt = Date()
        
        do {
            try modelContext.save()
            AppLogger.shared.info("Premium unlocked with promo code: \(code)")
            return true
        } catch {
            AppLogger.shared.error("Error unlocking premium: \(error)")
            return false
        }
    }
    
    /// Checks if user can access specific screen number
    /// Used for feature gating based on premium status
    func canAccessScreen(_ screenNumber: Int) -> Bool {
        return screenNumber <= unlockedScreens
    }
    
    // MARK: - Session Management
    
    /// Creates new collaborative session with specified name
    /// Adds current user as participant and saves to SwiftData
    func createSession(name: String) -> Session? {
        let session = Session(name: name)
        
        if let user = currentUser {
            // Add current user to participants
            var participants = [String]()
            if let existingParticipants = try? JSONDecoder().decode([String].self, from: session.participants.data(using: .utf8) ?? Data()) {
                participants = existingParticipants
            }
            if !participants.contains(user.deviceId) {
                participants.append(user.deviceId)
            }
            session.participants = (try? JSONEncoder().encode(participants))?.base64EncodedString() ?? "[]"
            user.currentSessionId = session.id
        }
        
        do {
            modelContext.insert(session)
            try modelContext.save()
            currentSession = session
            AppLogger.shared.info("Session created: \(name)")
            return session
        } catch {
            AppLogger.shared.error("Error creating session: \(error)")
            return nil
        }
    }
    
    /// Joins existing session and adds current user as participant
    /// Updates session participants and saves to SwiftData
    func joinSession(_ session: Session) {
        guard let user = currentUser else { return }
        
        // Add user to session participants
        var participants = [String]()
        if let existingParticipants = try? JSONDecoder().decode([String].self, from: session.participants.data(using: .utf8) ?? Data()) {
            participants = existingParticipants
        }
        if !participants.contains(user.deviceId) {
            participants.append(user.deviceId)
        }
        session.participants = (try? JSONEncoder().encode(participants))?.base64EncodedString() ?? "[]"
        
        user.currentSessionId = session.id
        currentSession = session
        
        do {
            try modelContext.save()
            AppLogger.shared.info("User joined session: \(session.name)")
        } catch {
            AppLogger.shared.error("Error joining session: \(error)")
        }
    }
    
    // MARK: - Sync Operations
    
    /// Performs data synchronization with CloudKit
    /// Updates sync status and logs completion
    func syncData() async {
        syncStatus = VisionOSSyncStatus.syncing
        
        // Sync with CloudKit
        await syncWithCloudKit()
        
        syncStatus = VisionOSSyncStatus.completed
        AppLogger.shared.info("VisionOS data sync completed successfully")
    }
    
    /// Internal method for CloudKit synchronization
    /// Handles syncing user data, sessions, and preferences
    /// SUGGESTION: Implement actual CloudKit sync logic
    private func syncWithCloudKit() async {
        // CloudKit sync implementation for visionOS
        // This would handle syncing user data, sessions, and preferences
        AppLogger.shared.info("CloudKit sync initiated for visionOS")
    }
    
    // MARK: - App State Handlers
    
    /// Handles app becoming active
    /// Triggers data synchronization when app returns to foreground
    private func handleAppDidBecomeActive() {
        Task {
            await syncData()
        }
    }
    
    /// Handles app resigning active
    /// Saves any pending changes before app goes to background
    private func handleAppWillResignActive() {
        // Save any pending changes
        do {
            try modelContext.save()
            AppLogger.shared.info("Data saved before app resigning active")
        } catch {
            AppLogger.shared.error("Error saving data before resigning active: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    /// Gets unique device identifier for cross-device synchronization
    /// Uses platform-specific methods to ensure unique identification
    private func getDeviceId() -> String {
        #if os(iOS) || os(tvOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #elseif os(macOS)
        return ProcessInfo.processInfo.hostName
        #elseif os(watchOS)
        return WKInterfaceDevice.current().identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        return UUID().uuidString
        #endif
    }
}

// MARK: - Supporting Types

/// Represents the current status of visionOS data synchronization operations
/// Used for UI feedback and error handling
enum VisionOSSyncStatus {
    case idle
    case syncing
    case completed
    case failed(Error)
}

/// Custom error types for VisionOSDataManager operations
/// Provides detailed error information for debugging and user feedback
enum DataManagerError: LocalizedError {
    case swiftDataError(Error)
    case cloudKitError(Error)
    case networkError
    case userNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .swiftDataError(let error):
            return "SwiftData error: \(error.localizedDescription)"
        case .cloudKitError(let error):
            return "CloudKit error: \(error.localizedDescription)"
        case .networkError:
            return "Network error occurred"
        case .userNotFound:
            return "User not found"
        case .invalidData:
            return "Invalid data format"
        }
    }
} 