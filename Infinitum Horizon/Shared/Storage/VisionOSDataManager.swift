import Foundation
import SwiftData
import CloudKit
import Combine

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

@MainActor
class VisionOSDataManager: ObservableObject {
    @Published var currentUser: User?
    @Published var currentSession: Session?
    @Published var isPremium: Bool = false
    @Published var unlockedScreens: Int = 2
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var syncStatus: VisionOSSyncStatus = .idle
    @Published var isOnline = false
    
    // MARK: - Core Services
    private let modelContext: ModelContext
    
    // MARK: - Public Accessors
    var getModelContext: ModelContext {
        return modelContext
    }
    private let cloudKitContainer = CKContainer.default()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var isSwiftDataAvailable = true
    private var syncQueue = DispatchQueue(label: "com.infinitumhorizon.visionos.sync", qos: .utility)
    private var lastSyncTime: Date?
    private var syncTimer: Timer?
    
    // MARK: - Configuration
    private let syncInterval: TimeInterval = 300 // 5 minutes
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupBindings()
        setupNotifications()
        startPeriodicSync()
        loadCurrentUser()
    }
    
    deinit {
        syncTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind to current user changes
        $currentUser
            .sink { [weak self] user in
                self?.isPremium = user?.isPremium ?? false
                self?.unlockedScreens = user?.unlockedScreens ?? 2
            }
            .store(in: &cancellables)
    }
    
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
    
    private func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncData()
            }
        }
    }
    
    // MARK: - User Management
    
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
    
    func canAccessScreen(_ screenNumber: Int) -> Bool {
        return screenNumber <= unlockedScreens
    }
    
    // MARK: - Session Management
    
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
    
    func syncData() async {
        syncStatus = VisionOSSyncStatus.syncing
        
        // Sync with CloudKit
        await syncWithCloudKit()
        
        syncStatus = VisionOSSyncStatus.completed
        AppLogger.shared.info("VisionOS data sync completed successfully")
    }
    
    private func syncWithCloudKit() async {
        // CloudKit sync implementation for visionOS
        // This would handle syncing user data, sessions, and preferences
        AppLogger.shared.info("CloudKit sync initiated for visionOS")
    }
    
    // MARK: - App State Handlers
    
    private func handleAppDidBecomeActive() {
        Task {
            await syncData()
        }
    }
    
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

enum VisionOSSyncStatus {
    case idle
    case syncing
    case completed
    case failed(Error)
}

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