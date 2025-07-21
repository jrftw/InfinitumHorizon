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
@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    // MARK: - Published Properties
    @Published var isInitialized = false
    @Published var currentFirebaseUser: FirebaseAuth.User?
    @Published var isOnline = false
    @Published var syncStatus: SyncStatus = .idle
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let auth = Auth.auth()
    private var cancellables = Set<AnyCancellable>()
    private var listeners: [String: ListenerRegistration] = [:]
    
    // MARK: - Initialization
    private init() {
        setupFirebase()
        setupAuthStateListener()
        setupNetworkMonitoring()
    }
    
    private func setupFirebase() {
        guard FirebaseApp.app() == nil else {
            isInitialized = true
            return
        }
        
        FirebaseApp.configure()
        isInitialized = true
        
        // Configure Crashlytics
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        
        // Configure Analytics
        Analytics.setAnalyticsCollectionEnabled(true)
        
        AppLogger.shared.info("Firebase initialized successfully")
    }
    
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
    
    private func setupNetworkMonitoring() {
        // Monitor network connectivity
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkConnectivity()
            }
            .store(in: &cancellables)
    }
    
    private func checkConnectivity() {
        // Simple connectivity check
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            Task { @MainActor in
                self?.isOnline = snapshot.value as? Bool ?? false
            }
        }
    }
    
    // MARK: - Authentication
    
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
    
    private func handleUserUpdate(_ user: User) {
        // Notify DataManager of user updates
        NotificationCenter.default.post(
            name: .firebaseUserUpdated,
            object: user
        )
    }
    
    private func handleSessionUpdate(_ session: Session) {
        // Notify DataManager of session updates
        NotificationCenter.default.post(
            name: .firebaseSessionUpdated,
            object: session
        )
    }
    
    // MARK: - Storage Operations
    
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
    
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
        AppLogger.shared.debug("Analytics event logged: \(name)")
    }
    
    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    // MARK: - Remote Config
    
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
    
    func getRemoteConfigValue(forKey key: String) -> String {
        let remoteConfig = RemoteConfig.remoteConfig()
        return remoteConfig.configValue(forKey: key).stringValue
    }
    
    // MARK: - Cleanup
    
    private func cleanupUserData() {
        // Remove all listeners
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
        
        // Clear current user
        currentFirebaseUser = nil
    }
    
    func removeListener(forKey key: String) {
        listeners[key]?.remove()
        listeners.removeValue(forKey: key)
    }
    
    // MARK: - Sync Status
    
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

enum SyncStatus {
    case idle
    case syncing
    case completed
    case failed(Error)
}

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

extension Notification.Name {
    static let firebaseUserUpdated = Notification.Name("firebaseUserUpdated")
    static let firebaseSessionUpdated = Notification.Name("firebaseSessionUpdated")
} 
#endif
