import Foundation
import SwiftData

@Model
final class User {
    // MARK: - Core Properties
    var id: String = UUID().uuidString
    var username: String = ""
    var email: String = ""
    var passwordHash: String = "" // Store hashed password, never plain text
    var deviceId: String = ""
    var platform: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - Account Status
    var isEmailVerified: Bool = false
    var emailVerificationToken: String?
    var emailVerificationExpiry: Date?
    var isActive: Bool = true
    var lastLoginAt: Date?
    var lastActiveAt: Date?
    
    // MARK: - Premium Features
    var isPremium: Bool = false
    var subscriptionType: String? // "monthly", "yearly", "lifetime"
    var subscriptionExpiryDate: Date?
    var promoCodeUsed: String?
    var unlockedScreens: Int = 2
    var totalScreens: Int = 10
    var adsEnabled: Bool = true
    
    // MARK: - Session Management
    var currentSessionId: String?
    
    // MARK: - Profile
    var displayName: String?
    var avatarURL: String?
    var bio: String?
    var preferences: String = "{}" // JSON string storage for user preferences
    
    // MARK: - Security
    var passwordResetToken: String?
    var passwordResetExpiry: Date?
    var failedLoginAttempts: Int = 0
    var accountLockedUntil: Date?
    
    init(
        username: String,
        email: String,
        passwordHash: String,
        deviceId: String,
        platform: String
    ) {
        self.username = username
        self.email = email.lowercased()
        self.passwordHash = passwordHash
        self.deviceId = deviceId
        self.platform = platform
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // Account status
        self.isEmailVerified = false
        self.isActive = true
        self.lastLoginAt = nil
        self.lastActiveAt = Date()
        
        // Premium features
        self.isPremium = false
        self.unlockedScreens = 2 // Free screens
        self.totalScreens = 10
        self.adsEnabled = true
        
        // Profile
        self.displayName = username
        self.preferences = "{}"
        
        // Security
        self.failedLoginAttempts = 0
        self.accountLockedUntil = nil
    }
    
    // MARK: - Computed Properties
    
    var isAccountLocked: Bool {
        guard let lockedUntil = accountLockedUntil else { return false }
        return Date() < lockedUntil
    }
    
    var canLogin: Bool {
        return isActive && !isAccountLocked
    }
    
    var subscriptionStatus: String {
        if !isPremium {
            return "Free"
        }
        
        guard let expiry = subscriptionExpiryDate else {
            return "Premium (No expiry)"
        }
        
        if Date() > expiry {
            return "Expired"
        }
        
        return "Premium (Expires \(expiry.formatted(date: .abbreviated, time: .omitted)))"
    }
    
    // MARK: - Validation
    
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func isValidUsername(_ username: String) -> Bool {
        // Username must be 3-20 characters, alphanumeric and underscores only
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        // Password must be at least 8 characters with at least one letter and one number
        return password.count >= 8 && 
               password.range(of: "[A-Za-z]", options: .regularExpression) != nil &&
               password.range(of: "[0-9]", options: .regularExpression) != nil
    }
    
    // MARK: - Security Methods
    
    func incrementFailedLoginAttempts() {
        failedLoginAttempts += 1
        
        // Lock account after 5 failed attempts for 15 minutes
        if failedLoginAttempts >= 5 {
            accountLockedUntil = Calendar.current.date(byAdding: .minute, value: 15, to: Date())
        }
    }
    
    func resetFailedLoginAttempts() {
        failedLoginAttempts = 0
        accountLockedUntil = nil
    }
    
    func updateLastLogin() {
        lastLoginAt = Date()
        lastActiveAt = Date()
        resetFailedLoginAttempts()
    }
    
    // MARK: - Email Verification
    
    func generateEmailVerificationToken() {
        emailVerificationToken = UUID().uuidString
        emailVerificationExpiry = Calendar.current.date(byAdding: .hour, value: 24, to: Date())
    }
    
    func verifyEmail(with token: String) -> Bool {
        guard let storedToken = emailVerificationToken,
              let expiry = emailVerificationExpiry,
              storedToken == token,
              Date() < expiry else {
            return false
        }
        
        isEmailVerified = true
        emailVerificationToken = nil
        emailVerificationExpiry = nil
        return true
    }
    
    // MARK: - Password Reset
    
    func generatePasswordResetToken() {
        passwordResetToken = UUID().uuidString
        passwordResetExpiry = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
    }
    
    func resetPassword(with token: String, newPasswordHash: String) -> Bool {
        guard let storedToken = passwordResetToken,
              let expiry = passwordResetExpiry,
              storedToken == token,
              Date() < expiry else {
            return false
        }
        
        passwordHash = newPasswordHash
        passwordResetToken = nil
        passwordResetExpiry = nil
        resetFailedLoginAttempts()
        return true
    }
}

// MARK: - Validation Errors
enum UserValidationError: LocalizedError {
    case invalidUsername
    case invalidEmail
    case invalidDeviceId
    case invalidPlatform
    
    var errorDescription: String? {
        switch self {
        case .invalidUsername:
            return "Username cannot be empty"
        case .invalidEmail:
            return "Email cannot be empty"
        case .invalidDeviceId:
            return "Device ID cannot be empty"
        case .invalidPlatform:
            return "Platform cannot be empty"
        }
    }
}
