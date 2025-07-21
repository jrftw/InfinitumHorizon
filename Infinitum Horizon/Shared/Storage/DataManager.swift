//
//  DataManager.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//  Updated 7/21/2025 by @jrftw
//
//  Core data management service for SwiftData operations and CloudKit synchronization
//  Handles user management, session tracking, premium features, and device positioning
//  Provides unified interface for local data persistence and cloud synchronization
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

// MARK: - Data Manager
/// Main data management service that handles SwiftData operations and CloudKit synchronization
/// Manages user data, sessions, premium features, and cross-device positioning
/// Uses @MainActor for UI thread safety and ObservableObject for SwiftUI integration
@MainActor
class DataManager: ObservableObject {
    // MARK: - Published Properties
    /// Current authenticated user for the app
    /// Updated automatically when user data changes
    @Published var currentUser: User?
    
    /// Current active session for collaborative features
    /// Manages multi-device session state
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
    
    // MARK: - Private Properties
    /// SwiftData model context for database operations
    private let modelContext: ModelContext
    
    /// CloudKit container for cloud synchronization
    private let cloudKitContainer = CKContainer.default()
    
    /// Combine cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Flag indicating if SwiftData is available and working
    /// Used for fallback behavior when data layer fails
    private var isSwiftDataAvailable = true
    
    // MARK: - Initialization
    /// Creates DataManager with SwiftData model context
    /// Sets up bindings and loads existing user data
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupBindings()
        loadCurrentUser()
    }
    
    // MARK: - Public Access
    
    /// Returns the SwiftData model context for direct database access
    /// Used by other components that need direct SwiftData operations
    func getModelContext() -> ModelContext {
        return modelContext
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
    
    /// Loads existing user from device storage
    /// Attempts to find user by device ID for seamless app experience
    private func loadCurrentUser() {
        // Try to load existing user from device
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
            } else {
                // Don't create a default user - let authentication handle this
                AppLogger.shared.info("No existing user found - waiting for authentication")
                currentUser = nil
            }
        } catch {
            AppLogger.shared.error("Error loading user: \(error)")
            // If SwiftData is completely broken, don't create a user
            currentUser = nil
            isSwiftDataAvailable = false
            errorMessage = "Data storage issues detected"
        }
    }
    
    /// Tests if SwiftData is available and working properly
    /// Used for fallback behavior when data layer fails
    private func testSwiftDataAvailability() -> Bool {
        do {
            // Try a simple fetch to test if SwiftData is working
            var descriptor = FetchDescriptor<User>()
            descriptor.fetchLimit = 1
            _ = try modelContext.fetch(descriptor)
            return true
        } catch {
            AppLogger.shared.error("SwiftData availability test failed: \(error)")
            return false
        }
    }
    
    // MARK: - Device Information
    
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
    
    // MARK: - User Management
    
    /// Saves user data to SwiftData with error handling
    /// Persists user changes to local storage
    func saveUser(_ user: User) async throws {
        do {
            try modelContext.save()
            AppLogger.shared.info("User saved successfully: \(user.username)")
        } catch {
            AppLogger.shared.error("Error saving user: \(error)")
            // In production, we might want to continue without throwing
            // to prevent app crashes, but for now we'll throw the error
            throw DataManagerError.swiftDataError(error)
        }
    }
    
    /// Finds user by email address (case-insensitive)
    /// Returns nil if no user found with matching email
    func findUserByEmail(_ email: String) -> User? {
        do {
            // Since emails are stored in lowercase in the User model,
            // we can use a direct predicate match with the lowercase email
            let lowercaseEmail = email.lowercased()
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate<User> { user in
                    user.email == lowercaseEmail
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
    
    /// Deletes user and all associated data
    /// Removes user from SwiftData and clears current user if applicable
    func deleteUser(_ user: User) async throws {
        do {
            modelContext.delete(user)
            try modelContext.save()
            if currentUser?.id == user.id {
                currentUser = nil
            }
            AppLogger.shared.info("User deleted successfully: \(user.username)")
        } catch {
            AppLogger.shared.error("Error deleting user: \(error)")
            throw DataManagerError.swiftDataError(error)
        }
    }
    
    // MARK: - Premium Features
    
    /// Unlocks premium features using promotional code
    /// Validates code and applies premium benefits if valid
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
            return true
        } catch {
            AppLogger.shared.error("Error unlocking premium: \(error)")
            return false
        }
    }
    
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
            AppLogger.shared.info("Premium purchased successfully")
        } catch {
            AppLogger.shared.error("Error purchasing premium: \(error)")
            errorMessage = "Failed to activate premium"
        }
    }
    
    /// Checks if user can access specific screen number
    /// Used for feature gating based on premium status
    func canAccessScreen(_ screenNumber: Int) -> Bool {
        return screenNumber <= unlockedScreens
    }
    
    // MARK: - Session Management
    
    /// Creates new collaborative session with specified name
    /// Adds current user as participant and sets as current session
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
            AppLogger.shared.info("Session created: \(session.name)")
            return session
        } catch {
            AppLogger.shared.error("Error creating session: \(error)")
            return nil
        }
    }
    
    /// Joins existing session by session ID
    /// Adds current user as participant and sets as current session
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
                // Add user to participants
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
            return true
        } catch {
            AppLogger.shared.error("Error joining session: \(error)")
            return false
        }
    }
    
    /// Updates device position in 3D space for current session
    /// Used for cross-device spatial awareness and positioning
    func updateDevicePosition(x: Double, y: Double, z: Double, rotation: Double) {
        guard let user = currentUser,
              let sessionId = user.currentSessionId else { return }
        
        let position = DevicePosition(
            x: x,
            y: y,
            z: z,
            rotation: rotation,
            deviceId: user.deviceId,
            sessionId: sessionId
        )
        
        do {
            modelContext.insert(position)
            try modelContext.save()
            AppLogger.shared.debug("Device position updated: x=\(x), y=\(y), z=\(z), rotation=\(rotation)")
        } catch {
            AppLogger.shared.error("Error updating device position: \(error)")
        }
    }
    
    // MARK: - Premium Features (Duplicate Section)
    /// POTENTIAL ISSUE: This section appears to be duplicated from above
    /// SUGGESTION: Remove duplicate section and consolidate premium functionality
    
    func applyPromoCode(_ code: String) -> Bool {
        guard let user = currentUser else { return false }
        
        // Simple promo code validation
        let validCodes = ["INFINITUM2025", "HORIZONFREE", "PREMIUM2025", "UNLOCKALL"]
        
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
    

    
    // MARK: - CloudKit Integration
    
    /// Synchronizes user data to CloudKit with retry logic
    /// Provides completion handler for operation feedback
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
        
        // Create CloudKit record
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
    
    /// Custom error types for DataManager operations
    /// Provides detailed error information for debugging and user feedback
    enum DataManagerError: LocalizedError {
        case noCurrentUser
        case cloudKitError(Error)
        case swiftDataError(Error)
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .noCurrentUser:
                return "No current user found"
            case .cloudKitError(let error):
                return "CloudKit error: \(error.localizedDescription)"
            case .swiftDataError(let error):
                return "SwiftData error: \(error.localizedDescription)"
            case .invalidData:
                return "Invalid data provided"
            }
        }
    }
} 
