//
//  CloudKitSchema.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//  Updated 7/21/2025 by @jrftw
//
//  CloudKit schema definitions and record creation utilities
//  Provides structured data mapping between SwiftData models and CloudKit records
//  Includes validation methods for data integrity and consistency
//

import Foundation
import CloudKit

// MARK: - CloudKit Schema
/// Defines CloudKit record types, field mappings, and validation rules
/// Provides utilities for converting SwiftData models to CloudKit records
/// Ensures data consistency across local and cloud storage
struct CloudKitSchema {
    
    // MARK: - Record Types
    /// CloudKit record type identifiers for different data entities
    /// Used to organize and query data in CloudKit databases
    static let userRecordType = "User"
    static let sessionRecordType = "Session"
    static let devicePositionRecordType = "DevicePosition"
    
    // MARK: - User Record Fields
    /// Field definitions for User records in CloudKit
    /// Maps User model properties to CloudKit record fields
    struct UserFields {
        /// Unique device identifier for cross-device synchronization
        static let deviceId = "deviceId"
        
        /// User's chosen username for display and identification
        static let username = "username"
        
        /// User's email address for authentication and notifications
        static let email = "email"
        
        /// Premium subscription status
        static let isPremium = "isPremium"
        
        /// Promotional code used for premium activation
        static let promoCodeUsed = "promoCodeUsed"
        
        /// Timestamp when user account was created
        static let createdAt = "createdAt"
        
        /// Timestamp of user's last activity
        static let lastActive = "lastActive"
        
        /// Platform identifier (iOS, macOS, visionOS, etc.)
        static let platform = "platform"
        
        /// Number of screens unlocked for user
        static let unlockedScreens = "unlockedScreens"
        
        /// Total number of screens available in app
        static let totalScreens = "totalScreens"
        
        /// Whether advertisements are enabled for user
        static let adsEnabled = "adsEnabled"
        
        /// Date when premium subscription expires
        static let subscriptionExpiryDate = "subscriptionExpiryDate"
        
        /// Current active session identifier
        static let currentSessionId = "currentSessionId"
    }
    
    // MARK: - Session Record Fields
    /// Field definitions for Session records in CloudKit
    /// Maps Session model properties to CloudKit record fields
    struct SessionFields {
        /// Human-readable name for the session
        static let name = "name"
        
        /// Timestamp when session was created
        static let createdAt = "createdAt"
        
        /// Timestamp of last activity in session
        static let lastActive = "lastActive"
        
        /// Whether session is currently active
        static let isActive = "isActive"
        
        /// JSON string containing participant device IDs
        static let participants = "participants"
    }
    
    // MARK: - Device Position Record Fields
    /// Field definitions for DevicePosition records in CloudKit
    /// Maps DevicePosition model properties to CloudKit record fields
    struct DevicePositionFields {
        /// X-coordinate position in 3D space
        static let x = "x"
        
        /// Y-coordinate position in 3D space
        static let y = "y"
        
        /// Z-coordinate position in 3D space
        static let z = "z"
        
        /// Rotation angle around Y-axis
        static let rotation = "rotation"
        
        /// Unique identifier of the device
        static let deviceId = "deviceId"
        
        /// Unique identifier of the session
        static let sessionId = "sessionId"
        
        /// Timestamp when position was recorded
        static let timestamp = "timestamp"
    }
    
    // MARK: - Schema Creation
    
    /// Creates CloudKit record from User model
    /// Maps all relevant User properties to CloudKit record fields
    /// SUGGESTION: Consider adding field validation before record creation
    static func createUserRecord(from user: User) -> CKRecord {
        let record = CKRecord(recordType: userRecordType)
        record[UserFields.deviceId] = user.deviceId
        record[UserFields.username] = user.username
        record[UserFields.email] = user.email
        record[UserFields.isPremium] = user.isPremium
        record[UserFields.promoCodeUsed] = user.promoCodeUsed
        record[UserFields.createdAt] = user.createdAt
        record[UserFields.lastActive] = user.lastActiveAt
        record[UserFields.platform] = user.platform
        record[UserFields.unlockedScreens] = user.unlockedScreens
        record[UserFields.totalScreens] = user.totalScreens
        record[UserFields.adsEnabled] = user.adsEnabled
        record[UserFields.subscriptionExpiryDate] = user.subscriptionExpiryDate
        record[UserFields.currentSessionId] = user.currentSessionId
        return record
    }
    
    /// Creates CloudKit record from Session model
    /// Maps all relevant Session properties to CloudKit record fields
    static func createSessionRecord(from session: Session) -> CKRecord {
        let record = CKRecord(recordType: sessionRecordType)
        record[SessionFields.name] = session.name
        record[SessionFields.createdAt] = session.createdAt
        record[SessionFields.lastActive] = session.lastActive
        record[SessionFields.isActive] = session.isActive
        record[SessionFields.participants] = session.participants
        return record
    }
    
    /// Creates CloudKit record from DevicePosition model
    /// Maps all relevant DevicePosition properties to CloudKit record fields
    static func createDevicePositionRecord(from position: DevicePosition) -> CKRecord {
        let record = CKRecord(recordType: devicePositionRecordType)
        record[DevicePositionFields.x] = position.x
        record[DevicePositionFields.y] = position.y
        record[DevicePositionFields.z] = position.z
        record[DevicePositionFields.rotation] = position.rotation
        record[DevicePositionFields.deviceId] = position.deviceId
        record[DevicePositionFields.sessionId] = position.sessionId
        record[DevicePositionFields.timestamp] = position.timestamp
        return record
    }
    
    // MARK: - Schema Validation
    
    /// Validates User record data integrity
    /// Checks that required fields are present and non-empty
    /// Returns true if record meets minimum validation requirements
    static func validateUserRecord(_ record: CKRecord) -> Bool {
        guard let deviceId = record[UserFields.deviceId] as? String,
              let username = record[UserFields.username] as? String,
              let platform = record[UserFields.platform] as? String else {
            return false
        }
        
        return !deviceId.isEmpty && !username.isEmpty && !platform.isEmpty
    }
    
    /// Validates Session record data integrity
    /// Checks that required fields are present and non-empty
    /// Returns true if record meets minimum validation requirements
    static func validateSessionRecord(_ record: CKRecord) -> Bool {
        guard let name = record[SessionFields.name] as? String else {
            return false
        }
        
        return !name.isEmpty
    }
    
    /// Validates DevicePosition record data integrity
    /// Checks that required fields are present and non-empty
    /// Returns true if record meets minimum validation requirements
    static func validateDevicePositionRecord(_ record: CKRecord) -> Bool {
        guard let deviceId = record[DevicePositionFields.deviceId] as? String,
              let sessionId = record[DevicePositionFields.sessionId] as? String else {
            return false
        }
        
        return !deviceId.isEmpty && !sessionId.isEmpty
    }
} 