import Foundation
import CloudKit

struct CloudKitSchema {
    
    // MARK: - Record Types
    
    static let userRecordType = "User"
    static let sessionRecordType = "Session"
    static let devicePositionRecordType = "DevicePosition"
    
    // MARK: - User Record Fields
    
    struct UserFields {
        static let deviceId = "deviceId"
        static let username = "username"
        static let email = "email"
        static let isPremium = "isPremium"
        static let promoCodeUsed = "promoCodeUsed"
        static let createdAt = "createdAt"
        static let lastActive = "lastActive"
        static let platform = "platform"
        static let unlockedScreens = "unlockedScreens"
        static let totalScreens = "totalScreens"
        static let adsEnabled = "adsEnabled"
        static let subscriptionExpiryDate = "subscriptionExpiryDate"
        static let currentSessionId = "currentSessionId"
    }
    
    // MARK: - Session Record Fields
    
    struct SessionFields {
        static let name = "name"
        static let createdAt = "createdAt"
        static let lastActive = "lastActive"
        static let isActive = "isActive"
        static let participants = "participants"
    }
    
    // MARK: - Device Position Record Fields
    
    struct DevicePositionFields {
        static let x = "x"
        static let y = "y"
        static let z = "z"
        static let rotation = "rotation"
        static let deviceId = "deviceId"
        static let sessionId = "sessionId"
        static let timestamp = "timestamp"
    }
    
    // MARK: - Schema Creation
    
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
    
    static func createSessionRecord(from session: Session) -> CKRecord {
        let record = CKRecord(recordType: sessionRecordType)
        record[SessionFields.name] = session.name
        record[SessionFields.createdAt] = session.createdAt
        record[SessionFields.lastActive] = session.lastActive
        record[SessionFields.isActive] = session.isActive
        record[SessionFields.participants] = session.participants
        return record
    }
    
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
    
    static func validateUserRecord(_ record: CKRecord) -> Bool {
        guard let deviceId = record[UserFields.deviceId] as? String,
              let username = record[UserFields.username] as? String,
              let platform = record[UserFields.platform] as? String else {
            return false
        }
        
        return !deviceId.isEmpty && !username.isEmpty && !platform.isEmpty
    }
    
    static func validateSessionRecord(_ record: CKRecord) -> Bool {
        guard let name = record[SessionFields.name] as? String else {
            return false
        }
        
        return !name.isEmpty
    }
    
    static func validateDevicePositionRecord(_ record: CKRecord) -> Bool {
        guard let deviceId = record[DevicePositionFields.deviceId] as? String,
              let sessionId = record[DevicePositionFields.sessionId] as? String else {
            return false
        }
        
        return !deviceId.isEmpty && !sessionId.isEmpty
    }
} 