import Foundation
import CryptoKit
import Combine
#if !os(visionOS)
import FirebaseAuth
import FirebaseFirestore
#endif
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

#if !os(visionOS)
@MainActor
class FirebaseAuthManager: ObservableObject, AuthenticationManager {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var authError: String?
    @Published var authMethod: AuthMethod = .none
    
    // MARK: - Core Services
    private let dataManager: HybridDataManager
    private let firebaseService: FirebaseService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Auth Method
    enum AuthMethod {
        case none
        case email
        case anonymous
        case google
        case apple
    }
    
    init(dataManager: HybridDataManager) {
        self.dataManager = dataManager
        self.firebaseService = FirebaseService.shared
        setupBindings()
        setupFirebaseAuthListener()
    }
    
    private func setupBindings() {
        // Bind to data manager's current user
        dataManager.$currentUser
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
            .store(in: &cancellables)
        
        // Bind to Firebase service
        firebaseService.$currentFirebaseUser
            .sink { [weak self] firebaseUser in
                if firebaseUser != nil {
                    self?.authMethod = firebaseUser?.isAnonymous == true ? .anonymous : .email
                } else {
                    self?.authMethod = .none
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupFirebaseAuthListener() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    // Firebase user is authenticated
                    self?.handleFirebaseAuthSuccess(user)
                } else {
                    // Firebase user signed out
                    self?.handleFirebaseAuthSignOut()
                }
            }
        }
    }
    
    // MARK: - Password Hashing
    
    private func hashPassword(_ password: String) -> String {
        let salt = "InfinitumHorizon2025" // In production, use unique salt per user
        let saltedPassword = password + salt
        let hashedData = SHA256.hash(data: saltedPassword.data(using: .utf8)!)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func verifyPassword(_ password: String, against hash: String) -> Bool {
        let hashedPassword = hashPassword(password)
        return hashedPassword == hash
    }
    
    // MARK: - Registration
    
    func register(
        username: String,
        email: String,
        password: String,
        confirmPassword: String,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        isLoading = true
        authError = nil
        
        // Validate input
        let validationResult = validateRegistrationInput(
            username: username,
            email: email,
            password: password,
            confirmPassword: confirmPassword
        )
        
        guard validationResult.isEmpty else {
            isLoading = false
            authError = validationResult.first?.localizedDescription
            completion(.failure(validationResult.first!))
            return
        }
        
        Task {
            do {
                // Check if user already exists locally
                if await userExists(email: email) {
                    isLoading = false
                    authError = "An account with this email already exists"
                    completion(.failure(AuthError.emailAlreadyExists))
                    return
                }
                
                if await usernameExists(username: username) {
                    isLoading = false
                    authError = "This username is already taken"
                    completion(.failure(AuthError.usernameAlreadyExists))
                    return
                }
                
                // Create Firebase user first
                _ = try await firebaseService.createUserWithEmail(email, password: password)
                
                // Create local user
                let passwordHash = hashPassword(password)
                let deviceId = getDeviceId()
                let platform = getCurrentPlatform()
                
                let newUser = User(
                    username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                    passwordHash: passwordHash,
                    deviceId: deviceId,
                    platform: platform
                )
                
                // Generate email verification token
                newUser.generateEmailVerificationToken()
                
                // Save user to local storage and Firebase
                try await dataManager.saveUser(newUser)
                
                // Set as current user
                dataManager.currentUser = newUser
                
                // Log analytics
                firebaseService.logEvent("user_registered", parameters: [
                    "method": "email",
                    "platform": platform
                ])
                
                isLoading = false
                completion(.success(newUser))
                
                // Send verification email
                await sendVerificationEmail(to: newUser)
                
            } catch let error as AuthErrorCode {
                isLoading = false
                let authError = mapFirebaseAuthError(error)
                self.authError = authError.localizedDescription
                completion(.failure(authError))
            } catch {
                isLoading = false
                authError = "Failed to create account: \(error.localizedDescription)"
                completion(.failure(AuthError.registrationFailed))
            }
        }
    }
    
    // MARK: - Login
    
    func login(
        email: String,
        password: String,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        isLoading = true
        authError = nil
        
        Task {
            do {
                // Try Firebase authentication first
                let firebaseUser = try await firebaseService.signInWithEmail(email, password: password)
                
                // Check if user exists locally
                guard let localUser = await findUserByEmail(email.lowercased()) else {
                    // Create local user from Firebase data
                    let newUser = await createLocalUserFromFirebase(firebaseUser)
                    dataManager.currentUser = newUser
                    
                    isLoading = false
                    completion(.success(newUser))
                    return
                }
                
                // Check if account is locked
                guard localUser.canLogin else {
                    isLoading = false
                    if localUser.isAccountLocked {
                        authError = "Account is temporarily locked. Please try again later."
                        completion(.failure(AuthError.accountLocked))
                    } else {
                        authError = "Account is deactivated"
                        completion(.failure(AuthError.accountDeactivated))
                    }
                    return
                }
                
                // Verify password locally as well
                guard verifyPassword(password, against: localUser.passwordHash) else {
                    localUser.incrementFailedLoginAttempts()
                    try await dataManager.saveUser(localUser)
                    
                    isLoading = false
                    authError = "Invalid email or password"
                    completion(.failure(AuthError.invalidCredentials))
                    return
                }
                
                // Successful login
                localUser.updateLastLogin()
                try await dataManager.saveUser(localUser)
                
                dataManager.currentUser = localUser
                
                // Log analytics
                firebaseService.logEvent("user_login", parameters: [
                    "method": "email",
                    "platform": localUser.platform
                ])
                
                isLoading = false
                completion(.success(localUser))
                
            } catch let error as AuthErrorCode {
                isLoading = false
                let authError = mapFirebaseAuthError(error)
                self.authError = authError.localizedDescription
                completion(.failure(authError))
            } catch {
                isLoading = false
                authError = "Login failed: \(error.localizedDescription)"
                completion(.failure(AuthError.loginFailed))
            }
        }
    }
    
    // MARK: - Anonymous Authentication
    
    func signInAnonymously(completion: @escaping (Result<User, Error>) -> Void) {
        isLoading = true
        authError = nil
        
        Task {
            do {
                let firebaseUser = try await firebaseService.signInAnonymously()
                
                // Create or get local user
                let localUser = await getOrCreateLocalUser(for: firebaseUser)
                dataManager.currentUser = localUser
                
                // Log analytics
                firebaseService.logEvent("user_login", parameters: [
                    "method": "anonymous",
                    "platform": localUser.platform
                ])
                
                isLoading = false
                completion(.success(localUser))
                
            } catch {
                isLoading = false
                authError = "Anonymous sign-in failed: \(error.localizedDescription)"
                completion(.failure(AuthError.loginFailed))
            }
        }
    }
    
    // MARK: - Logout
    
    func logout() {
        Task {
            do {
                // Sign out from Firebase
                try firebaseService.signOut()
                
                // Clear local user
                dataManager.currentUser = nil
                isAuthenticated = false
                currentUser = nil
                authMethod = .none
                
                // Log analytics
                firebaseService.logEvent("user_logout")
                
            } catch {
                AppLogger.shared.error("Error during logout: \(error)")
            }
        }
    }
    
    // MARK: - Delete Account
    
    func deleteAccount(completion: @escaping (Bool) -> Void) {
        guard let user = currentUser else {
            completion(false)
            return
        }
        
        Task {
            do {
                // Delete from Firebase
                if let firebaseUser = firebaseService.currentFirebaseUser {
                    try await firebaseUser.delete()
                }
                
                // Delete from local storage
                try await dataManager.deleteUser(user)
                
                // Clear current user
                dataManager.currentUser = nil
                isAuthenticated = false
                currentUser = nil
                authMethod = .none
                
                // Log analytics
                firebaseService.logEvent("user_deleted")
                
                completion(true)
            } catch {
                AppLogger.shared.error("Error deleting account: \(error)")
                completion(false)
            }
        }
    }
    
    // MARK: - Email Verification
    
    func sendVerificationEmail(to user: User) async {
        do {
            if let firebaseUser = firebaseService.currentFirebaseUser {
                try await firebaseUser.sendEmailVerification()
                AppLogger.shared.info("Verification email sent to: \(user.email)")
            }
        } catch {
            AppLogger.shared.error("Failed to send verification email: \(error)")
        }
    }
    
    func verifyEmail(token: String, completion: @escaping (Bool) -> Void) {
        guard let user = currentUser else {
            completion(false)
            return
        }
        
        Task {
            do {
                let success = user.verifyEmail(with: token)
                if success {
                    try await dataManager.saveUser(user)
                    dataManager.currentUser = user
                    
                    // Log analytics
                    firebaseService.logEvent("email_verified")
                }
                completion(success)
            } catch {
                completion(false)
            }
        }
    }
    
    // MARK: - Password Reset
    
    func requestPasswordReset(email: String, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
                AppLogger.shared.info("Password reset email sent to: \(email)")
                
                // Log analytics
                firebaseService.logEvent("password_reset_requested")
                
                completion(true)
            } catch {
                AppLogger.shared.error("Failed to send password reset email: \(error)")
                completion(false)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleFirebaseAuthSuccess(_ firebaseUser: FirebaseAuth.User) {
        Task {
            let localUser = await getOrCreateLocalUser(for: firebaseUser)
            dataManager.currentUser = localUser
        }
    }
    
    private func handleFirebaseAuthSignOut() {
        dataManager.currentUser = nil
        isAuthenticated = false
        currentUser = nil
        authMethod = .none
    }
    
    private func getOrCreateLocalUser(for firebaseUser: FirebaseAuth.User) async -> User {
        let deviceId = getDeviceId()
        let platform = getCurrentPlatform()
        
        // Try to find existing user by device ID
        if let existingUser = dataManager.currentUser {
            return existingUser
        }
        
        // Create new user
        let username = firebaseUser.isAnonymous ? "Anonymous_\(deviceId.prefix(8))" : "User_\(deviceId.prefix(8))"
        let email = firebaseUser.email ?? "\(username.lowercased())@example.com"
        
        let newUser = User(
            username: username,
            email: email,
            passwordHash: "", // No password for anonymous users
            deviceId: deviceId,
            platform: platform
        )
        
        // Set email verification status
        if !firebaseUser.isAnonymous {
            newUser.isEmailVerified = firebaseUser.isEmailVerified
        }
        
        do {
            try await dataManager.saveUser(newUser)
        } catch {
            AppLogger.shared.error("Failed to save local user: \(error)")
        }
        
        return newUser
    }
    
    private func createLocalUserFromFirebase(_ firebaseUser: FirebaseAuth.User) async -> User {
        let deviceId = getDeviceId()
        let platform = getCurrentPlatform()
        let username = "User_\(deviceId.prefix(8))"
        let email = firebaseUser.email ?? "\(username.lowercased())@example.com"
        
        let newUser = User(
            username: username,
            email: email,
            passwordHash: "", // Will be set when user changes password
            deviceId: deviceId,
            platform: platform
        )
        
        newUser.isEmailVerified = firebaseUser.isEmailVerified
        
        do {
            try await dataManager.saveUser(newUser)
        } catch {
            AppLogger.shared.error("Failed to save local user from Firebase: \(error)")
        }
        
        return newUser
    }
    
    private func mapFirebaseAuthError(_ error: AuthErrorCode) -> AuthError {
        switch error.code {
        case .emailAlreadyInUse:
            return .emailAlreadyExists
        case .invalidEmail:
            return .invalidEmail
        case .weakPassword:
            return .invalidPassword
        case .userNotFound:
            return .invalidCredentials
        case .wrongPassword:
            return .invalidCredentials
        case .tooManyRequests:
            return .accountLocked
        case .userDisabled:
            return .accountDeactivated
        default:
            return .loginFailed
        }
    }
    
    // MARK: - Validation
    
    private func validateRegistrationInput(
        username: String,
        email: String,
        password: String,
        confirmPassword: String
    ) -> [Error] {
        var errors: [Error] = []
        
        if !User.isValidUsername(username) {
            errors.append(AuthError.invalidUsername)
        }
        
        if !User.isValidEmail(email) {
            errors.append(AuthError.invalidEmail)
        }
        
        if !User.isValidPassword(password) {
            errors.append(AuthError.invalidPassword)
        }
        
        if password != confirmPassword {
            errors.append(AuthError.passwordsDoNotMatch)
        }
        
        return errors
    }
    
    // MARK: - Database Queries
    
    private func userExists(email: String) async -> Bool {
        return await findUserByEmail(email) != nil
    }
    
    private func usernameExists(username: String) async -> Bool {
        return await findUserByUsername(username) != nil
    }
    
    private func findUserByEmail(_ email: String) async -> User? {
        // This would query the database in production
        // For now, we'll use the data manager
        return dataManager.currentUser?.email == email ? dataManager.currentUser : nil
    }
    
    private func findUserByUsername(_ username: String) async -> User? {
        return dataManager.currentUser?.username == username ? dataManager.currentUser : nil
    }
    
    // MARK: - Utility
    
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
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidUsername
    case invalidEmail
    case invalidPassword
    case passwordsDoNotMatch
    case emailAlreadyExists
    case usernameAlreadyExists
    case invalidCredentials
    case accountLocked
    case accountDeactivated
    case emailNotVerified
    case registrationFailed
    case loginFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidUsername:
            return "Username must be 3-20 characters and contain only letters, numbers, and underscores"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPassword:
            return "Password must be at least 8 characters with at least one letter and one number"
        case .passwordsDoNotMatch:
            return "Passwords do not match"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .usernameAlreadyExists:
            return "This username is already taken"
        case .invalidCredentials:
            return "Invalid email or password"
        case .accountLocked:
            return "Account is temporarily locked due to too many failed login attempts"
        case .accountDeactivated:
            return "Account has been deactivated"
        case .emailNotVerified:
            return "Please verify your email address before logging in"
        case .registrationFailed:
            return "Failed to create account. Please try again"
        case .loginFailed:
            return "Login failed. Please try again"
        case .networkError:
            return "Network error. Please check your connection"
        }
    }
} 
#endif