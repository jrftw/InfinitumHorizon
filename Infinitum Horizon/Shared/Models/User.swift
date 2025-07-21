//
//  User.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//  Updated 7/21/2025 by @jrftw
//
//  SwiftData model for User entities with comprehensive authentication and premium features
//  Handles user authentication, session management, premium subscriptions, and security features
//  Includes validation methods, email verification, password reset, and account security
//

import Foundation
import SwiftData

// MARK: - User Model
/// Comprehensive user model that handles authentication, premium features, and account management
/// Provides full user lifecycle management from registration to premium subscription handling
/// Integrates with Firebase authentication and local SwiftData persistence
@Model
final class User {
    // MARK: - Core Properties
    /// Unique identifier for the user, auto-generated using UUID
    /// Used for SwiftData relationships and Firebase user identification
    var id: String = UUID().uuidString
    
    /// User's chosen username for display and login
    /// Must be 3-20 characters, alphanumeric and underscores only
    var username: String = ""
    
    /// User's email address for authentication and notifications
    /// Stored in lowercase for consistency and case-insensitive matching
    var email: String = ""
    
    /// Hashed password for secure authentication
    /// Never stores plain text passwords - only cryptographic hashes
    var passwordHash: String = "" // Store hashed password, never plain text
    
    /// Unique device identifier for cross-device synchronization
    /// Used to track user activity across multiple devices
    var deviceId: String = ""
    
    /// Platform identifier (iOS, macOS, tvOS, watchOS, visionOS)
    /// Used for platform-specific feature availability and UI adaptation
    var platform: String = ""
    
    /// Timestamp when the user account was created
    /// Used for account age calculations and analytics
    var createdAt: Date = Date()
    
    /// Timestamp when the user account was last updated
    /// Tracks modifications for sync and conflict resolution
    var updatedAt: Date = Date()
    
    // MARK: - Account Status
    /// Indicates whether the user's email has been verified
    /// Required for full account functionality and security
    var isEmailVerified: Bool = false
    
    /// Temporary token for email verification process
    /// Generated when user requests email verification
    var emailVerificationToken: String?
    
    /// Expiration date for email verification token
    /// Tokens expire after 24 hours for security
    var emailVerificationExpiry: Date?
    
    /// Indicates if the account is active and can be used
    /// Can be set to false for account suspension or deletion
    var isActive: Bool = true
    
    /// Timestamp of the user's last successful login
    /// Used for security monitoring and user activity tracking
    var lastLoginAt: Date?
    
    /// Timestamp of the user's last activity in the app
    /// Updated periodically during app usage for engagement metrics
    var lastActiveAt: Date?
    
    // MARK: - Premium Features
    /// Indicates whether the user has premium subscription
    /// Controls access to premium features and content
    var isPremium: Bool = false
    
    /// Type of subscription (monthly, yearly, lifetime)
    /// Used for billing management and feature access control
    var subscriptionType: String? // "monthly", "yearly", "lifetime"
    
    /// Date when the premium subscription expires
    /// Used to determine if premium features should be disabled
    var subscriptionExpiryDate: Date?
    
    /// Promotional code used during subscription
    /// Tracked for marketing analytics and discount management
    var promoCodeUsed: String?
    
    /// Number of screens unlocked for the user
    /// Free users get 2 screens, premium users get more
    var unlockedScreens: Int = 2
    
    /// Total number of screens available in the app
    /// Used to calculate progress and encourage upgrades
    var totalScreens: Int = 10
    
    /// Whether advertisements are enabled for this user
    /// Premium users typically have ads disabled
    var adsEnabled: Bool = true
    
    // MARK: - Session Management
    /// Current active session identifier
    /// Used for session tracking and security validation
    var currentSessionId: String?
    
    // MARK: - Profile
    /// User's display name for public profile
    /// Can be different from username for privacy
    var displayName: String?
    
    /// URL to user's avatar/profile picture
    /// Stored as string for flexibility with different image services
    var avatarURL: String?
    
    /// User's biographical information
    /// Optional text field for user self-description
    var bio: String?
    
    /// JSON string containing user preferences
    /// Flexible storage for app settings and customization
    var preferences: String = "{}" // JSON string storage for user preferences
    
    // MARK: - Security
    /// Temporary token for password reset process
    /// Generated when user requests password reset
    var passwordResetToken: String?
    
    /// Expiration date for password reset token
    /// Tokens expire after 1 hour for security
    var passwordResetExpiry: Date?
    
    /// Counter for failed login attempts
    /// Used to implement account lockout for security
    var failedLoginAttempts: Int = 0
    
    /// Date until which the account is locked
    /// Set after multiple failed login attempts
    var accountLockedUntil: Date?
    
    // MARK: - Initialization
    /// Creates a new User instance with required authentication information
    /// Sets up default values for all optional properties
    /// SUGGESTION: Consider adding validation during initialization
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
    
    /// Determines if the account is currently locked due to failed login attempts
    /// Returns true if account is locked and lock period hasn't expired
    var isAccountLocked: Bool {
        guard let lockedUntil = accountLockedUntil else { return false }
        return Date() < lockedUntil
    }
    
    /// Determines if the user can currently log in
    /// Checks both account activity status and lock status
    var canLogin: Bool {
        return isActive && !isAccountLocked
    }
    
    /// Human-readable subscription status for UI display
    /// Returns appropriate status based on premium status and expiry
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
    
    /// Validates email format using regex pattern
    /// Ensures email follows standard email format requirements
    /// SUGGESTION: Consider using more robust email validation library
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validates username format and length
    /// Ensures username meets security and display requirements
    static func isValidUsername(_ username: String) -> Bool {
        // Username must be 3-20 characters, alphanumeric and underscores only
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
    
    /// Validates password strength requirements
    /// Ensures password meets minimum security standards
    /// SUGGESTION: Consider adding more password complexity requirements
    static func isValidPassword(_ password: String) -> Bool {
        // Password must be at least 8 characters with at least one letter and one number
        return password.count >= 8 && 
               password.range(of: "[A-Za-z]", options: .regularExpression) != nil &&
               password.range(of: "[0-9]", options: .regularExpression) != nil
    }
    
    // MARK: - Security Methods
    
    /// Increments failed login attempt counter and locks account if threshold reached
    /// Implements security measure to prevent brute force attacks
    /// POTENTIAL ISSUE: Consider implementing exponential backoff for lockout periods
    func incrementFailedLoginAttempts() {
        failedLoginAttempts += 1
        
        // Lock account after 5 failed attempts for 15 minutes
        if failedLoginAttempts >= 5 {
            accountLockedUntil = Calendar.current.date(byAdding: .minute, value: 15, to: Date())
        }
    }
    
    /// Resets failed login attempts and removes account lock
    /// Called after successful login or password reset
    func resetFailedLoginAttempts() {
        failedLoginAttempts = 0
        accountLockedUntil = nil
    }
    
    /// Updates login timestamps and resets security counters
    /// Called after successful authentication
    func updateLastLogin() {
        lastLoginAt = Date()
        lastActiveAt = Date()
        resetFailedLoginAttempts()
    }
    
    // MARK: - Email Verification
    
    /// Generates a new email verification token with 24-hour expiration
    /// Used for email verification workflow
    func generateEmailVerificationToken() {
        emailVerificationToken = UUID().uuidString
        emailVerificationExpiry = Calendar.current.date(byAdding: .hour, value: 24, to: Date())
    }
    
    /// Verifies email using provided token
    /// Returns true if token is valid and not expired
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
    
    /// Generates a new password reset token with 1-hour expiration
    /// Used for password reset workflow
    func generatePasswordResetToken() {
        passwordResetToken = UUID().uuidString
        passwordResetExpiry = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
    }
    
    /// Resets password using provided token and new password hash
    /// Returns true if token is valid and not expired
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
/// Custom error types for user validation failures
/// Provides localized error descriptions for UI display
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
