//
//  HybridDataManager.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//  Updated 7/21/2025 by @jrftw
//
//  Hybrid data management service that combines SwiftData, Firebase, and CloudKit
//  Provides seamless data synchronization across local storage and cloud services
//  Handles platform-specific Firebase availability and fallback mechanisms
//

import Foundation
import SwiftData
import CloudKit
import Combine
#if !os(visionOS)
import FirebaseCore
#endif
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

// MARK: - Hybrid Data Manager
/// Advanced data management service that combines multiple storage backends
/// Provides seamless synchronization between SwiftData, Firebase, and CloudKit
/// Handles platform-specific limitations (Firebase excluded from visionOS)
/// Uses @MainActor for UI thread safety and ObservableObject for SwiftUI integration
@MainActor
class HybridDataManager: ObservableObject {
    // MARK: - Published Properties
    /// Current authenticated user for the app
    /// Updated automatically when user data changes across all storage backends
    @Published var currentUser: User?
    
    /// Current active session for collaborative features
    /// Manages multi-device session state with cloud synchronization
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
    /// Set when data operations fail across any backend
    @Published var errorMessage: String?
    
    /// Current synchronization status across all backends
    /// Provides feedback on sync operations for UI updates
    @Published var syncStatus: SyncStatus = .idle
    
    /// Network connectivity status for cloud operations
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
    
    /// Firebase service instance (nil on visionOS due to compatibility issues)
    #if !os(visionOS)
    private let firebaseService: FirebaseService?
    #else
    private let firebaseService: FirebaseService?
    #endif
    
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
    private var syncQueue = DispatchQueue(label: "com.infinitumhorizon.sync", qos: .utility)
    
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
    /// Creates HybridDataManager with SwiftData model context
    /// Sets up Firebase service (if available) and initializes all subsystems
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        #if !os(visionOS)
        self.firebaseService = FirebaseService.shared
        #else
        self.firebaseService = nil
        #endif
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
    /// Binds to Firebase service properties when available
    private func setupBindings() {
        // Bind to current user changes
        $currentUser
            .sink { [weak self] user in
                self?.isPremium = user?.isPremium ?? false
                self?.unlockedScreens = user?.unlockedScreens ?? 2
            }
            .store(in: &cancellables)
        
        // Bind to Firebase service (only if available)
        #if !os(visionOS)
        if let firebaseService = firebaseService {
            firebaseService.$isOnline
                .assign(to: \.isOnline, on: self)
                .store(in: &cancellables)
            
            firebaseService.$syncStatus
                .assign(to: \.syncStatus, on: self)
                .store(in: &cancellables)
        }
        #endif
    }
    
    /// Sets up notification observers for Firebase updates
    /// Listens for user and session updates from Firebase service
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFirebaseUserUpdate),
            name: .firebaseUserUpdated,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFirebaseSessionUpdate),
            name: .firebaseSessionUpdated,
            object: nil
        )
    }
    
    /// Starts periodic synchronization timer
    /// Automatically syncs data at configured intervals
    private func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performPeriodicSync()
            }
        }
    }
    
    // MARK: - User Management
    
    /// Loads existing user from device storage or creates new user
    /// Attempts to find user by device ID for seamless app experience
    /// Falls back to creating default or minimal user if needed
    private func loadCurrentUser() {
        let deviceId = getDeviceId()
        
        do {
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate<User> { user in
                    user.deviceId == deviceId
                }
            )
            let users = try modelContext.fetch(descriptor)
            
            if let existingUser = users.first {
                currentUser = existingUser
                AppLogger.shared.info("Loaded existing user: \(existingUser.username)")
                
                // Sync with Firebase if available
                Task {
                    await syncUserWithFirebase(existingUser)
                }
            } else {
                createDefaultUser(deviceId: deviceId)
            }
        } catch {
            AppLogger.shared.error("Error loading user: \(error)")
            createMinimalUser(deviceId: deviceId)
        }
    }
    
    /// Creates a new user with default settings
    /// Used when no existing user is found on device
    private func createDefaultUser(deviceId: String) {
        let platform = getCurrentPlatform()
        let username = "User_\(deviceId.prefix(8))"
        
        let newUser = User(
            username: username,
            email: "\(username.lowercased())@example.com",
            passwordHash: "",
            deviceId: deviceId,
            platform: platform
        )
        
        do {
            modelContext.insert(newUser)
            try modelContext.save()
            currentUser = newUser
            AppLogger.shared.info("Created new user: \(username)")
            
            // Sync to Firebase
            Task {
                await syncUserWithFirebase(newUser)
            }
        } catch {
            AppLogger.shared.error("Error creating user: \(error)")
            createMinimalUser(deviceId: deviceId)
        }
    }
    
    /// Creates a minimal user when SwiftData is unavailable
    /// Used as fallback when data storage fails
    private func createMinimalUser(deviceId: String) {
        let platform = getCurrentPlatform()
        let username = "User_\(deviceId.prefix(8))"
        
        let minimalUser = User(
            username: username,
            email: "\(username.lowercased())@example.com",
            passwordHash: "",
            deviceId: deviceId,
            platform: platform
        )
        
        currentUser = minimalUser
        isSwiftDataAvailable = false
        AppLogger.shared.warning("Created minimal user due to SwiftData issues: \(username)")
        errorMessage = "Using offline mode due to data storage issues"
    }
    
    // MARK: - Hybrid Sync Operations
    
    /// Saves user data to all available storage backends
    /// Prioritizes local SwiftData for speed, then syncs to cloud services
    /// Handles failures gracefully without losing local data
    func saveUser(_ user: User) async throws {
        // Save to SwiftData first (fastest)
        do {
            try modelContext.save()
            AppLogger.shared.info("User saved to SwiftData: \(user.username)")
        } catch {
            AppLogger.shared.error("Error saving user to SwiftData: \(error)")
            throw DataManagerError.swiftDataError(error)
        }
        
        // Sync to Firebase (if available)
        if let firebaseService = firebaseService,
           firebaseService.isInitialized && firebaseService.currentFirebaseUser != nil {
            do {
                try await firebaseService.saveUser(user)
                AppLogger.shared.info("User synced to Firebase: \(user.username)")
            } catch {
                AppLogger.shared.warning("Failed to sync user to Firebase: \(error)")
                // Don't throw here - local save was successful
            }
        }
        
        // Sync to CloudKit (Apple ecosystem)
        if isOnline {
            syncToCloudKit { result in
                switch result {
                case .success:
                    AppLogger.shared.info("User synced to CloudKit: \(user.username)")
                case .failure(let error):
                    AppLogger.shared.warning("Failed to sync user to CloudKit: \(error)")
                }
            }
        }
    }
    
    /// Synchronizes user data with Firebase service
    /// Handles anonymous authentication and user data upload
    private func syncUserWithFirebase(_ user: User) async {
        #if !os(visionOS)
        guard let firebaseService = firebaseService, firebaseService.isInitialized else { return }
        
        do {
            // Try to sign in anonymously if not authenticated
            if firebaseService.currentFirebaseUser == nil {
                _ = try await firebaseService.signInAnonymously()
            }
            
            // Save user to Firebase
            try await firebaseService.saveUser(user)
            AppLogger.shared.info("User synced to Firebase: \(user.username)")
        } catch {
            AppLogger.shared.warning("Failed to sync user with Firebase: \(error)")
        }
        #endif
    }
    
    /// Performs periodic synchronization from cloud to local storage
    /// Updates local data with latest cloud data at regular intervals
    private func performPeriodicSync() async {
        guard isOnline, let _ = currentUser else { return }
        
        // Don't sync too frequently
        if let lastSync = lastSyncTime, Date().timeIntervalSince(lastSync) < syncInterval {
            return
        }
        
        #if !os(visionOS)
        do {
            // Sync from Firebase to local
            if let firebaseService = firebaseService,
               let firebaseUser = try await firebaseService.fetchUser() {
                // Update local user with Firebase data
                updateLocalUserWithFirebaseData(firebaseUser)
                try modelContext.save()
                AppLogger.shared.info("Periodic sync completed successfully")
            }
            
            lastSyncTime = Date()
        } catch {
            AppLogger.shared.warning("Periodic sync failed: \(error)")
        }
        #endif
    }
    
    /// Updates local user data with Firebase user data
    /// Merges cloud data with local data, prioritizing cloud for certain fields
    private func updateLocalUserWithFirebaseData(_ firebaseUser: User) {
        guard let localUser = currentUser else { return }
        
        // Update fields that might have changed on other devices
        localUser.isPremium = firebaseUser.isPremium
        localUser.unlockedScreens = firebaseUser.unlockedScreens
        localUser.adsEnabled = firebaseUser.adsEnabled
        localUser.subscriptionExpiryDate = firebaseUser.subscriptionExpiryDate
        localUser.promoCodeUsed = firebaseUser.promoCodeUsed
        localUser.displayName = firebaseUser.displayName
        localUser.avatarURL = firebaseUser.avatarURL
        localUser.bio = firebaseUser.bio
        localUser.preferences = firebaseUser.preferences
        localUser.updatedAt = Date()
        
        currentUser = localUser
    }
    
    // MARK: - Firebase Integration Handlers
    
    /// Handles user updates from Firebase service
    /// Updates local user data when Firebase data changes
    @objc private func handleFirebaseUserUpdate(_ notification: Notification) {
        guard let firebaseUser = notification.object as? User else { return }
        
        Task { @MainActor in
            updateLocalUserWithFirebaseData(firebaseUser)
            
            do {
                try modelContext.save()
                AppLogger.shared.info("Local user updated from Firebase")
            } catch {
                AppLogger.shared.error("Failed to save local user update: \(error)")
            }
        }
    }
    
    /// Handles session updates from Firebase service
    /// Updates local session data when Firebase data changes
    @objc private func handleFirebaseSessionUpdate(_ notification: Notification) {
        guard let firebaseSession = notification.object as? Session else { return }
        
        Task { @MainActor in
            // Update or create local session
            if let existingSession = currentSession, existingSession.id == firebaseSession.id {
                // Update existing session
                existingSession.name = firebaseSession.name
                existingSession.lastActive = firebaseSession.lastActive
                existingSession.isActive = firebaseSession.isActive
                existingSession.participants = firebaseSession.participants
            } else {
                // Create new session
                modelContext.insert(firebaseSession)
                currentSession = firebaseSession
            }
            
            do {
                try modelContext.save()
                AppLogger.shared.info("Local session updated from Firebase")
            } catch {
                AppLogger.shared.error("Failed to save local session update: \(error)")
            }
        }
    }
    
    // MARK: - Session Management
    
    /// Creates new collaborative session with specified name
    /// Adds current user as participant and syncs to all available backends
    func createSession(name: String) -> Session? {
        let session = Session(name: name)
        
        if let user = currentUser {
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
            AppLogger.shared.info("Session created: \(session.name)")
            
            // Sync to Firebase
            #if !os(visionOS)
            Task {
                do {
                    try await firebaseService?.saveSession(session)
                    firebaseService?.setupSessionSync(sessionId: session.id)
                } catch {
                    AppLogger.shared.warning("Failed to sync session to Firebase: \(error)")
                }
            }
            #endif
            
            return session
        } catch {
            AppLogger.shared.error("Error creating session: \(error)")
            return nil
        }
    }
    
    /// Joins existing session by session ID
    /// Adds current user as participant and syncs to all available backends
    func joinSession(_ sessionId: String) -> Bool {
        do {
            let descriptor = FetchDescriptor<Session>(
                predicate: #Predicate<Session> { session in
                    session.id == sessionId
                }
            )
            let sessions = try modelContext.fetch(descriptor)
            
            guard let session = sessions.first else {
                return false
            }
            
            if let user = currentUser {
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
            
            session.lastActive = Date()
            try modelContext.save()
            currentSession = session
            AppLogger.shared.info("Joined session: \(session.name)")
            
            // Sync to Firebase
            #if !os(visionOS)
            Task {
                do {
                    try await firebaseService?.saveSession(session)
                    firebaseService?.setupSessionSync(sessionId: session.id)
                } catch {
                    AppLogger.shared.warning("Failed to sync session to Firebase: \(error)")
                }
            }
            #endif
            
            return true
        } catch {
            AppLogger.shared.error("Error joining session: \(error)")
            return false
        }
    }
    
    // MARK: - Premium Features
    
    /// Unlocks premium features using promotional code
    /// Validates code and applies premium benefits across all storage backends
    /// SUGGESTION: Consider moving promo codes to server-side validation
    func unlockPremiumWithPromoCode(_ code: String) -> Bool {
        let validCodes = ["INFINITUM2025", "HORIZONFREE", "PREMIUM2025", "UNLOCKALL"]
        
        guard validCodes.contains(code.uppercased()) else {
            return false
        }
        
        guard let user = currentUser else { return false }
        
        user.isPremium = true
        user.promoCodeUsed = code.uppercased()
        user.unlockedScreens = user.totalScreens
        user.adsEnabled = false
        user.subscriptionExpiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        user.updatedAt = Date()
        
        do {
            try modelContext.save()
            AppLogger.shared.info("Premium unlocked with promo code: \(code)")
            
            // Sync to Firebase
            #if !os(visionOS)
            Task {
                do {
                    try await firebaseService?.saveUser(user)
                } catch {
                    AppLogger.shared.warning("Failed to sync premium unlock to Firebase: \(error)")
                }
            }
            #endif
            
            return true
        } catch {
            AppLogger.shared.error("Error unlocking premium: \(error)")
            return false
        }
    }
    
    /// Purchases premium subscription for current user
    /// Updates user status and unlocks all features across all storage backends
    func purchasePremium() {
        guard let user = currentUser else { return }
        
        user.isPremium = true
        user.unlockedScreens = user.totalScreens
        user.adsEnabled = false
        user.subscriptionExpiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        user.updatedAt = Date()
        
        do {
            try modelContext.save()
            AppLogger.shared.info("Premium purchased successfully")
            
            // Sync to Firebase
            #if !os(visionOS)
            Task {
                do {
                    try await firebaseService?.saveUser(user)
                } catch {
                    AppLogger.shared.warning("Failed to sync premium purchase to Firebase: \(error)")
                }
            }
            #endif
        } catch {
            AppLogger.shared.error("Error purchasing premium: \(error)")
            errorMessage = "Failed to activate premium"
        }
    }
    
    // MARK: - User Management
    
    /// Deletes user and all associated data from all storage backends
    /// Removes user from SwiftData, Firebase, and CloudKit
    func deleteUser(_ user: User) async throws {
        // Delete from SwiftData first
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
        
        // Delete from Firebase (if available)
        #if !os(visionOS)
        if let firebaseService = firebaseService,
           firebaseService.isInitialized && firebaseService.currentFirebaseUser != nil {
            do {
                try await firebaseService.deleteUser(user)
                AppLogger.shared.info("User deleted from Firebase: \(user.username)")
            } catch {
                AppLogger.shared.warning("Failed to delete user from Firebase: \(error)")
                // Don't throw here - local delete was successful
            }
        }
        #endif
    }
    
    // MARK: - Screen Access Control
    
    /// Checks if user can access specific screen number
    /// Used for feature gating based on premium status
    func canAccessScreen(_ screenNumber: Int) -> Bool {
        return screenNumber <= unlockedScreens
    }
    

    
    // MARK: - User Search Methods
    
    /// Finds user by email address (case-insensitive)
    /// Returns nil if no user found with matching email
    func findUserByEmail(_ email: String) -> User? {
        do {
            let lowercasedEmail = email.lowercased()
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate<User> { user in
                    user.email == lowercasedEmail
                }
            )
            let users = try modelContext.fetch(descriptor)
            return users.first
        } catch {
            AppLogger.shared.error("Error finding user by email: \(error)")
            return nil
        }
    }
    
    /// Finds user by username (exact match)
    /// Returns nil if no user found with matching username
    func findUserByUsername(_ username: String) -> User? {
        do {
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate<User> { user in
                    user.username == username
                }
            )
            let users = try modelContext.fetch(descriptor)
            return users.first
        } catch {
            AppLogger.shared.error("Error finding user by username: \(error)")
            return nil
        }
    }
    
    /// Finds user by password reset token
    /// Used for password reset workflow
    func findUserByResetToken(_ token: String) -> User? {
        do {
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate<User> { user in
                    user.passwordResetToken == token
                }
            )
            let users = try modelContext.fetch(descriptor)
            return users.first
        } catch {
            AppLogger.shared.error("Error finding user by reset token: \(error)")
            return nil
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
    
    /// Gets current platform identifier for feature availability
    /// Used for platform-specific functionality and analytics
    private func getCurrentPlatform() -> String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(visionOS)
        return "visionOS"
        #elseif os(watchOS)
        return "watchOS"
        #else
        return "Unknown"
        #endif
    }
    
    // MARK: - CloudKit Integration (Legacy Support)
    
    /// Synchronizes user data to CloudKit with retry logic
    /// Provides completion handler for operation feedback
    /// SUGGESTION: Consider deprecating in favor of Firebase for consistency
    func syncToCloudKit(completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        syncToCloudKitWithRetry(maxRetries: 3, completion: completion)
    }
    
    /// Internal method for CloudKit sync with retry logic
    /// Attempts sync operation with exponential backoff
    private func syncToCloudKitWithRetry(maxRetries: Int, currentRetry: Int = 0, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = currentUser else {
            completion(.failure(DataManagerError.noCurrentUser))
            return
        }
        
        let record = CloudKitSchema.createUserRecord(from: user)
        
        cloudKitContainer.privateCloudDatabase.save(record) { [weak self] record, error in
            if let error = error {
                AppLogger.shared.error("CloudKit sync error: \(error)")
                
                if currentRetry < maxRetries {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(currentRetry + 1)) {
                        self?.syncToCloudKitWithRetry(maxRetries: maxRetries, currentRetry: currentRetry + 1, completion: completion)
                    }
                } else {
                    completion(.failure(DataManagerError.cloudKitError(error)))
                }
            } else {
                AppLogger.shared.info("CloudKit sync successful")
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Error Types
    
    /// Custom error types for HybridDataManager operations
    /// Provides detailed error information for debugging and user feedback
    enum DataManagerError: LocalizedError {
        case noCurrentUser
        case cloudKitError(Error)
        case swiftDataError(Error)
        case firebaseError(Error)
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .noCurrentUser:
                return "No current user found"
            case .cloudKitError(let error):
                return "CloudKit error: \(error.localizedDescription)"
            case .swiftDataError(let error):
                return "SwiftData error: \(error.localizedDescription)"
            case .firebaseError(let error):
                return "Firebase error: \(error.localizedDescription)"
            case .invalidData:
                return "Invalid data provided"
            }
        }
    }
} 