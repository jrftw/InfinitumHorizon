//
//  FirebaseService.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//  Updated 7/21/2025 by @jrftw
//
//  Comprehensive Firebase service for authentication, data persistence, and real-time synchronization
//  Handles user authentication, Firestore operations, storage, analytics, and remote configuration
//  Excluded from visionOS builds due to Firebase compatibility issues
//

import Foundation
#if !os(visionOS)
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebaseMessaging
import FirebaseRemoteConfig
import FirebaseDatabase
#endif
import Combine

#if !os(visionOS)
// MARK: - Firebase Service
/// Main service class for all Firebase operations including authentication, data persistence, and real-time sync
/// Provides a unified interface for Firebase functionality with proper error handling and state management
/// Uses @MainActor for UI thread safety and ObservableObject for SwiftUI integration
@MainActor
class FirebaseService: ObservableObject {
    // MARK: - Singleton Instance
    /// Shared singleton instance for app-wide Firebase access
    /// Ensures consistent Firebase state across the entire application
    static let shared = FirebaseService()
    
    // MARK: - Published Properties
    /// Indicates whether Firebase has been successfully initialized
    /// Used to determine if Firebase operations are available
    @Published var isInitialized = false
    
    /// Current authenticated Firebase user
    /// Updated automatically when authentication state changes
    @Published var currentFirebaseUser: FirebaseAuth.User?
    
    /// Network connectivity status for Firebase operations
    /// Monitored periodically to ensure reliable data synchronization
    @Published var isOnline = false
    
    /// Current synchronization status for data operations
    /// Provides feedback on sync operations for UI updates
    @Published var syncStatus: SyncStatus = .idle
    
    // MARK: - Private Properties
    /// Firestore database instance for document operations
    private let db = Firestore.firestore()
    
    /// Firebase Storage instance for file uploads
    private let storage = Storage.storage()
    
    /// Firebase Auth instance for authentication operations
    private let auth = Auth.auth()
    
    /// Combine cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Active Firestore listeners for real-time updates
    /// Keyed by listener identifier for proper cleanup
    private var listeners: [String: ListenerRegistration] = [:]
    
    // MARK: - Initialization
    /// Private initializer that sets up Firebase and monitoring
    /// Ensures Firebase is properly configured before use
    private init() {
        setupFirebase()
        setupAuthStateListener()
        setupNetworkMonitoring()
    }
    
    // MARK: - Firebase Setup
    /// Configures Firebase services and initializes core functionality
    /// Sets up Crashlytics and Analytics for monitoring and debugging
    private func setupFirebase() {
        guard FirebaseApp.app() == nil else {
            isInitialized = true
            return
        }
        
        FirebaseApp.configure()
        isInitialized = true
        
        // Configure Crashlytics for crash reporting
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        
        // Configure Analytics for user behavior tracking
        Analytics.setAnalyticsCollectionEnabled(true)
        
        AppLogger.shared.info("Firebase initialized successfully")
    }
    
    // MARK: - Authentication State Management
    /// Sets up listener for Firebase authentication state changes
    /// Automatically handles user login/logout and data synchronization
    private func setupAuthStateListener() {
        _ = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentFirebaseUser = user
                if user != nil {
                    self?.setupUserDataSync()
                } else {
                    self?.cleanupUserData()
                }
            }
        }
    }
    
    // MARK: - Network Monitoring
    /// Sets up periodic network connectivity monitoring
    /// Checks Firebase connectivity every 30 seconds
    private func setupNetworkMonitoring() {
        // Monitor network connectivity
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkConnectivity()
            }
            .store(in: &cancellables)
    }
    
    /// Checks Firebase connectivity using Realtime Database
    /// Updates isOnline status based on connection state
    private func checkConnectivity() {
        // Simple connectivity check using Realtime Database
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            Task { @MainActor in
                self?.isOnline = snapshot.value as? Bool ?? false
            }
        }
    }
    
    // MARK: - Authentication Operations
    
    /// Signs in user anonymously without requiring credentials
    /// Useful for quick app access and guest functionality
    func signInAnonymously() async throws -> FirebaseAuth.User {
        do {
            let result = try await auth.signInAnonymously()
            AppLogger.shared.info("Anonymous sign-in successful")
            return result.user
        } catch {
            AppLogger.shared.error("Anonymous sign-in failed: \(error)")
            throw FirebaseError.authenticationFailed(error)
        }
    }
    
    /// Signs in user with email and password credentials
    /// Validates credentials against Firebase Auth
    func signInWithEmail(_ email: String, password: String) async throws -> FirebaseAuth.User {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            AppLogger.shared.info("Email sign-in successful for: \(email)")
            return result.user
        } catch {
            AppLogger.shared.error("Email sign-in failed: \(error)")
            throw FirebaseError.authenticationFailed(error)
        }
    }
    
    /// Creates new user account with email and password
    /// Automatically signs in the new user upon successful creation
    func createUserWithEmail(_ email: String, password: String) async throws -> FirebaseAuth.User {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            AppLogger.shared.info("User creation successful for: \(email)")
            return result.user
        } catch {
            AppLogger.shared.error("User creation failed: \(error)")
            throw FirebaseError.authenticationFailed(error)
        }
    }
    
    /// Signs out current user and cleans up local data
    /// Removes all listeners and clears user state
    func signOut() throws {
        do {
            try auth.signOut()
            AppLogger.shared.info("Sign out successful")
        } catch {
            AppLogger.shared.error("Sign out failed: \(error)")
            throw FirebaseError.authenticationFailed(error)
        }
    }
    
    // MARK: - Firestore Operations
    
    /// Saves user data to Firestore with merge option
    /// Updates existing document or creates new one if doesn't exist
    func saveUser(_ user: User) async throws {
        guard let firebaseUser = currentFirebaseUser else {
            throw FirebaseError.noAuthenticatedUser
        }
        
        do {
            let userData = try user.toFirestoreData()
            try await db.collection("users").document(firebaseUser.uid).setData(userData, merge: true)
            AppLogger.shared.info("User saved to Firestore: \(user.username)")
        } catch {
            AppLogger.shared.error("Failed to save user to Firestore: \(error)")
            throw FirebaseError.firestoreError(error)
        }
    }
    
    /// Fetches user data from Firestore
    /// Returns nil if user document doesn't exist
    func fetchUser() async throws -> User? {
        guard let firebaseUser = currentFirebaseUser else {
            throw FirebaseError.noAuthenticatedUser
        }
        
        do {
            let document = try await db.collection("users").document(firebaseUser.uid).getDocument()
            guard document.exists, let data = document.data() else {
                return nil
            }
            
            let user = try User.fromFirestoreData(data)
            AppLogger.shared.info("User fetched from Firestore: \(user.username)")
            return user
        } catch {
            AppLogger.shared.error("Failed to fetch user from Firestore: \(error)")
            throw FirebaseError.firestoreError(error)
        }
    }
    
    /// Deletes user and all associated data from Firestore
    /// Removes user document and all subcollections
    func deleteUser(_ user: User) async throws {
        guard let firebaseUser = currentFirebaseUser else {
            throw FirebaseError.noAuthenticatedUser
        }
        
        do {
            // Delete user document from Firestore
            try await db.collection("users").document(firebaseUser.uid).delete()
            
            // Delete user's sessions subcollection
            let sessionsSnapshot = try await db.collection("users").document(firebaseUser.uid)
                .collection("sessions").getDocuments()
            
            for document in sessionsSnapshot.documents {
                try await document.reference.delete()
            }
            
            AppLogger.shared.info("User deleted from Firestore: \(user.username)")
        } catch {
            AppLogger.shared.error("Failed to delete user from Firestore: \(error)")
            throw FirebaseError.firestoreError(error)
        }
    }
    
    /// Saves session data to user's sessions subcollection
    /// Creates or updates session document in Firestore
    func saveSession(_ session: Session) async throws {
        guard let firebaseUser = currentFirebaseUser else {
            throw FirebaseError.noAuthenticatedUser
        }
        
        do {
            let sessionData = try session.toFirestoreData()
            try await db.collection("users").document(firebaseUser.uid)
                .collection("sessions").document(session.id).setData(sessionData)
            AppLogger.shared.info("Session saved to Firestore: \(session.name)")
        } catch {
            AppLogger.shared.error("Failed to save session to Firestore: \(error)")
            throw FirebaseError.firestoreError(error)
        }
    }
    
    /// Fetches all sessions for current user from Firestore
    /// Returns array of Session objects from user's sessions subcollection
    func fetchSessions() async throws -> [Session] {
        guard let firebaseUser = currentFirebaseUser else {
            throw FirebaseError.noAuthenticatedUser
        }
        
        do {
            let snapshot = try await db.collection("users").document(firebaseUser.uid)
                .collection("sessions").getDocuments()
            
            let sessions = try snapshot.documents.compactMap { document in
                try Session.fromFirestoreData(document.data())
            }
            
            AppLogger.shared.info("Fetched \(sessions.count) sessions from Firestore")
            return sessions
        } catch {
            AppLogger.shared.error("Failed to fetch sessions from Firestore: \(error)")
            throw FirebaseError.firestoreError(error)
        }
    }
    
    // MARK: - Real-time Updates
    
    /// Sets up real-time listener for user data changes
    /// Automatically notifies app when user data is updated in Firestore
    func setupUserDataSync() {
        guard let firebaseUser = currentFirebaseUser else { return }
        
        // Listen for user data changes
        let userListener = db.collection("users").document(firebaseUser.uid)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                if let error = error {
                    AppLogger.shared.error("User data listener error: \(error)")
                    return
                }
                
                guard let document = documentSnapshot, document.exists,
                      let data = document.data() else { return }
                
                Task { @MainActor in
                    do {
                        let user = try User.fromFirestoreData(data)
                        self?.handleUserUpdate(user)
                    } catch {
                        AppLogger.shared.error("Failed to parse user data: \(error)")
                    }
                }
            }
        
        listeners["user"] = userListener
    }
    
    /// Sets up real-time listener for specific session changes
    /// Automatically notifies app when session data is updated in Firestore
    func setupSessionSync(sessionId: String) {
        guard let firebaseUser = currentFirebaseUser else { return }
        
        let sessionListener = db.collection("users").document(firebaseUser.uid)
            .collection("sessions").document(sessionId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                if let error = error {
                    AppLogger.shared.error("Session listener error: \(error)")
                    return
                }
                
                guard let document = documentSnapshot, document.exists,
                      let data = document.data() else { return }
                
                Task { @MainActor in
                    do {
                        let session = try Session.fromFirestoreData(data)
                        self?.handleSessionUpdate(session)
                    } catch {
                        AppLogger.shared.error("Failed to parse session data: \(error)")
                    }
                }
            }
        
        listeners["session_\(sessionId)"] = sessionListener
    }
    
    /// Handles user data updates from real-time listeners
    /// Posts notification to notify other parts of the app
    private func handleUserUpdate(_ user: User) {
        // Notify DataManager of user updates
        NotificationCenter.default.post(
            name: .firebaseUserUpdated,
            object: user
        )
    }
    
    /// Handles session data updates from real-time listeners
    /// Posts notification to notify other parts of the app
    private func handleSessionUpdate(_ session: Session) {
        // Notify DataManager of session updates
        NotificationCenter.default.post(
            name: .firebaseSessionUpdated,
            object: session
        )
    }
    
    // MARK: - Storage Operations
    
    /// Uploads user avatar image to Firebase Storage
    /// Returns download URL for the uploaded image
    func uploadUserAvatar(_ imageData: Data, userId: String) async throws -> URL {
        let storageRef = storage.reference().child("avatars/\(userId).jpg")
        
        do {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await storageRef.downloadURL()
            
            AppLogger.shared.info("Avatar uploaded successfully")
            return downloadURL
        } catch {
            AppLogger.shared.error("Failed to upload avatar: \(error)")
            throw FirebaseError.storageError(error)
        }
    }
    
    // MARK: - Analytics
    
    /// Logs custom analytics event with optional parameters
    /// Used for tracking user behavior and app usage
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
        AppLogger.shared.debug("Analytics event logged: \(name)")
    }
    
    /// Sets user property for analytics tracking
    /// Used for user segmentation and behavior analysis
    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    // MARK: - Remote Config
    
    /// Fetches and activates remote configuration
    /// Updates app behavior based on server-side configuration
    func fetchRemoteConfig() async throws {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour
        remoteConfig.configSettings = settings
        
        do {
            let status = try await remoteConfig.fetchAndActivate()
            AppLogger.shared.info("Remote config fetched and activated: \(status)")
        } catch {
            AppLogger.shared.error("Failed to fetch remote config: \(error)")
            throw FirebaseError.remoteConfigError(error)
        }
    }
    
    /// Retrieves remote configuration value for specified key
    /// Returns string value or empty string if not found
    func getRemoteConfigValue(forKey key: String) -> String {
        let remoteConfig = RemoteConfig.remoteConfig()
        return remoteConfig.configValue(forKey: key).stringValue
    }
    
    // MARK: - Cleanup
    
    /// Cleans up user data and removes all listeners
    /// Called when user signs out or authentication state changes
    private func cleanupUserData() {
        // Remove all listeners
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
        
        // Clear current user
        currentFirebaseUser = nil
    }
    
    /// Removes specific listener by key
    /// Used for cleaning up individual listeners when no longer needed
    func removeListener(forKey key: String) {
        listeners[key]?.remove()
        listeners.removeValue(forKey: key)
    }
    
    // MARK: - Data Synchronization
    
    /// Performs full data synchronization from Firestore
    /// Updates local data with latest cloud data
    func syncData() async {
        syncStatus = .syncing
        
        do {
            // Sync user data
            if let user = try await fetchUser() {
                handleUserUpdate(user)
            }
            
            // Sync sessions
            let sessions = try await fetchSessions()
            for session in sessions {
                handleSessionUpdate(session)
            }
            
            syncStatus = .completed
            AppLogger.shared.info("Data sync completed successfully")
        } catch {
            syncStatus = .failed(error)
            AppLogger.shared.error("Data sync failed: \(error)")
        }
    }
}

// MARK: - Supporting Types

/// Represents the current status of data synchronization operations
/// Used for UI feedback and error handling
enum SyncStatus {
    case idle
    case syncing
    case completed
    case failed(Error)
}

/// Custom error types for Firebase operations
/// Provides detailed error information for debugging and user feedback
enum FirebaseError: LocalizedError {
    case notInitialized
    case noAuthenticatedUser
    case authenticationFailed(Error)
    case firestoreError(Error)
    case storageError(Error)
    case remoteConfigError(Error)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Firebase is not initialized"
        case .noAuthenticatedUser:
            return "No authenticated user found"
        case .authenticationFailed(let error):
            return "Authentication failed: \(error.localizedDescription)"
        case .firestoreError(let error):
            return "Firestore error: \(error.localizedDescription)"
        case .storageError(let error):
            return "Storage error: \(error.localizedDescription)"
        case .remoteConfigError(let error):
            return "Remote config error: \(error.localizedDescription)"
        case .networkError:
            return "Network error occurred"
        }
    }
}

// MARK: - Notification Names

/// Extension for Firebase-related notification names
/// Used for communicating Firebase events across the app
extension Notification.Name {
    static let firebaseUserUpdated = Notification.Name("firebaseUserUpdated")
    static let firebaseSessionUpdated = Notification.Name("firebaseSessionUpdated")
}
#endif
