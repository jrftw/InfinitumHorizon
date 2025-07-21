import Foundation
import CryptoKit
import Combine
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

@MainActor
class AuthManager: ObservableObject, AuthenticationManager {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var authError: String?
    
    private let dataManager: HybridDataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(dataManager: HybridDataManager) {
        self.dataManager = dataManager
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind to data manager's current user
        dataManager.$currentUser
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
            .store(in: &cancellables)
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
        
        // Check if user already exists
        Task {
            do {
                if await userExists(email: email) {
                    isLoading = false
                    authError = "An account with this email already exists"
                    completion(.failure(LocalAuthError.emailAlreadyExists))
                    return
                }
                
                if await usernameExists(username: username) {
                    isLoading = false
                    authError = "This username is already taken"
                    completion(.failure(LocalAuthError.usernameAlreadyExists))
                    return
                }
                
                // Create new user
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
                
                // Save user
                try await dataManager.saveUser(newUser)
                
                // Set as current user
                dataManager.currentUser = newUser
                
                isLoading = false
                completion(.success(newUser))
                
                // Send verification email (in production)
                await sendVerificationEmail(to: newUser)
                
            } catch {
                isLoading = false
                authError = "Failed to create account: \(error.localizedDescription)"
                completion(.failure(LocalAuthError.registrationFailed))
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
                guard let user = await findUserByEmail(email.lowercased()) else {
                    isLoading = false
                    authError = "Invalid email or password"
                    completion(.failure(LocalAuthError.invalidCredentials))
                    return
                }
                
                // Check if account is locked
                guard user.canLogin else {
                    isLoading = false
                    if user.isAccountLocked {
                        authError = "Account is temporarily locked. Please try again later."
                        completion(.failure(LocalAuthError.accountLocked))
                    } else {
                        authError = "Account is deactivated"
                        completion(.failure(LocalAuthError.accountDeactivated))
                    }
                    return
                }
                
                // Verify password
                guard verifyPassword(password, against: user.passwordHash) else {
                    user.incrementFailedLoginAttempts()
                    try await dataManager.saveUser(user)
                    
                    isLoading = false
                    authError = "Invalid email or password"
                    completion(.failure(LocalAuthError.invalidCredentials))
                    return
                }
                
                // Successful login
                user.updateLastLogin()
                try await dataManager.saveUser(user)
                
                dataManager.currentUser = user
                
                isLoading = false
                completion(.success(user))
                
            } catch {
                isLoading = false
                authError = "Login failed: \(error.localizedDescription)"
                completion(.failure(LocalAuthError.loginFailed))
            }
        }
    }
    
    // MARK: - Logout
    
    func logout() {
        dataManager.currentUser = nil
        isAuthenticated = false
        currentUser = nil
    }
    
    // MARK: - Delete Account
    
    func deleteAccount(completion: @escaping (Bool) -> Void) {
        guard let user = currentUser else {
            completion(false)
            return
        }
        
        Task {
            do {
                // Delete user from database
                try await dataManager.deleteUser(user)
                
                // Clear current user
                dataManager.currentUser = nil
                isAuthenticated = false
                currentUser = nil
                
                completion(true)
            } catch {
                #if DEBUG
                print("Error deleting account: \(error)")
                #endif
                completion(false)
            }
        }
    }
    
    // MARK: - Email Verification
    
    func sendVerificationEmail(to user: User) async {
        // In production, this would send an actual email
        // For now, we'll just simulate it
        #if DEBUG
        print("Verification email would be sent to: \(user.email)")
        print("Verification token: \(user.emailVerificationToken ?? "None")")
        #endif
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
                }
                completion(success)
            } catch {
                completion(false)
            }
        }
    }
    
    func resendVerificationEmail(completion: @escaping (Bool) -> Void) {
        guard let user = currentUser else {
            completion(false)
            return
        }
        
        Task {
            do {
                user.generateEmailVerificationToken()
                try await dataManager.saveUser(user)
                await sendVerificationEmail(to: user)
                completion(true)
            } catch {
                completion(false)
            }
        }
    }
    
    // MARK: - Password Reset
    
    func requestPasswordReset(email: String, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                guard let user = await findUserByEmail(email.lowercased()) else {
                    completion(false)
                    return
                }
                
                user.generatePasswordResetToken()
                try await dataManager.saveUser(user)
                
                // In production, send reset email
                #if DEBUG
                print("Password reset email would be sent to: \(user.email)")
                print("Reset token: \(user.passwordResetToken ?? "None")")
                #endif
                
                completion(true)
            } catch {
                completion(false)
            }
        }
    }
    
    func resetPassword(token: String, newPassword: String, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                guard let user = await findUserByResetToken(token) else {
                    completion(false)
                    return
                }
                
                let passwordHash = hashPassword(newPassword)
                let success = user.resetPassword(with: token, newPasswordHash: passwordHash)
                
                if success {
                    try await dataManager.saveUser(user)
                    if user.id == currentUser?.id {
                        dataManager.currentUser = user
                    }
                }
                
                completion(success)
            } catch {
                completion(false)
            }
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
        
        // Username validation
        if !User.isValidUsername(username) {
            errors.append(LocalAuthError.invalidUsername)
        }
        
        // Email validation
        if !User.isValidEmail(email) {
            errors.append(LocalAuthError.invalidEmail)
        }
        
        // Password validation
        if !User.isValidPassword(password) {
            errors.append(LocalAuthError.invalidPassword)
        }
        
        // Password confirmation
        if password != confirmPassword {
            errors.append(LocalAuthError.passwordsDoNotMatch)
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
        return dataManager.findUserByEmail(email)
    }
    
    private func findUserByUsername(_ username: String) async -> User? {
        return dataManager.findUserByUsername(username)
    }
    
    private func findUserByResetToken(_ token: String) async -> User? {
        return dataManager.findUserByResetToken(token)
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

enum LocalAuthError: LocalizedError {
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