import Foundation
import FirebaseFirestore

// MARK: - User Firestore Extensions

extension User {
    func toFirestoreData() throws -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "username": username,
            "email": email,
            "passwordHash": passwordHash,
            "deviceId": deviceId,
            "platform": platform,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "isEmailVerified": isEmailVerified,
            "isActive": isActive,
            "isPremium": isPremium,
            "unlockedScreens": unlockedScreens,
            "totalScreens": totalScreens,
            "adsEnabled": adsEnabled,
            "preferences": preferences,
            "failedLoginAttempts": failedLoginAttempts
        ]
        
        // Optional fields
        if let emailVerificationToken = emailVerificationToken {
            data["emailVerificationToken"] = emailVerificationToken
        }
        if let emailVerificationExpiry = emailVerificationExpiry {
            data["emailVerificationExpiry"] = Timestamp(date: emailVerificationExpiry)
        }
        if let lastLoginAt = lastLoginAt {
            data["lastLoginAt"] = Timestamp(date: lastLoginAt)
        }
        if let lastActiveAt = lastActiveAt {
            data["lastActiveAt"] = Timestamp(date: lastActiveAt)
        }
        if let subscriptionType = subscriptionType {
            data["subscriptionType"] = subscriptionType
        }
        if let subscriptionExpiryDate = subscriptionExpiryDate {
            data["subscriptionExpiryDate"] = Timestamp(date: subscriptionExpiryDate)
        }
        if let promoCodeUsed = promoCodeUsed {
            data["promoCodeUsed"] = promoCodeUsed
        }
        if let currentSessionId = currentSessionId {
            data["currentSessionId"] = currentSessionId
        }
        if let displayName = displayName {
            data["displayName"] = displayName
        }
        if let avatarURL = avatarURL {
            data["avatarURL"] = avatarURL
        }
        if let bio = bio {
            data["bio"] = bio
        }
        if let passwordResetToken = passwordResetToken {
            data["passwordResetToken"] = passwordResetToken
        }
        if let passwordResetExpiry = passwordResetExpiry {
            data["passwordResetExpiry"] = Timestamp(date: passwordResetExpiry)
        }
        if let accountLockedUntil = accountLockedUntil {
            data["accountLockedUntil"] = Timestamp(date: accountLockedUntil)
        }
        
        return data
    }
    
    static func fromFirestoreData(_ data: [String: Any]) throws -> User {
        guard let id = data["id"] as? String,
              let username = data["username"] as? String,
              let email = data["email"] as? String,
              let passwordHash = data["passwordHash"] as? String,
              let deviceId = data["deviceId"] as? String,
              let platform = data["platform"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp else {
            throw FirestoreError.invalidData("Missing required user fields")
        }
        
        let user = User(
            username: username,
            email: email,
            passwordHash: passwordHash,
            deviceId: deviceId,
            platform: platform
        )
        
        // Set the ID explicitly since it's already generated
        user.id = id
        user.createdAt = createdAtTimestamp.dateValue()
        user.updatedAt = updatedAtTimestamp.dateValue()
        
        // Set optional fields
        user.isEmailVerified = data["isEmailVerified"] as? Bool ?? false
        user.isActive = data["isActive"] as? Bool ?? true
        user.isPremium = data["isPremium"] as? Bool ?? false
        user.unlockedScreens = data["unlockedScreens"] as? Int ?? 2
        user.totalScreens = data["totalScreens"] as? Int ?? 10
        user.adsEnabled = data["adsEnabled"] as? Bool ?? true
        user.preferences = data["preferences"] as? String ?? "{}"
        user.failedLoginAttempts = data["failedLoginAttempts"] as? Int ?? 0
        
        // Optional timestamp fields
        if let lastLoginTimestamp = data["lastLoginAt"] as? Timestamp {
            user.lastLoginAt = lastLoginTimestamp.dateValue()
        }
        if let lastActiveTimestamp = data["lastActiveAt"] as? Timestamp {
            user.lastActiveAt = lastActiveTimestamp.dateValue()
        }
        if let subscriptionExpiryTimestamp = data["subscriptionExpiryDate"] as? Timestamp {
            user.subscriptionExpiryDate = subscriptionExpiryTimestamp.dateValue()
        }
        if let emailVerificationExpiryTimestamp = data["emailVerificationExpiry"] as? Timestamp {
            user.emailVerificationExpiry = emailVerificationExpiryTimestamp.dateValue()
        }
        if let passwordResetExpiryTimestamp = data["passwordResetExpiry"] as? Timestamp {
            user.passwordResetExpiry = passwordResetExpiryTimestamp.dateValue()
        }
        if let accountLockedUntilTimestamp = data["accountLockedUntil"] as? Timestamp {
            user.accountLockedUntil = accountLockedUntilTimestamp.dateValue()
        }
        
        // Optional string fields
        user.emailVerificationToken = data["emailVerificationToken"] as? String
        user.subscriptionType = data["subscriptionType"] as? String
        user.promoCodeUsed = data["promoCodeUsed"] as? String
        user.currentSessionId = data["currentSessionId"] as? String
        user.displayName = data["displayName"] as? String
        user.avatarURL = data["avatarURL"] as? String
        user.bio = data["bio"] as? String
        user.passwordResetToken = data["passwordResetToken"] as? String
        
        return user
    }
}

// MARK: - Session Firestore Extensions

extension Session {
    func toFirestoreData() throws -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "name": name,
            "createdAt": Timestamp(date: createdAt),
            "lastActive": Timestamp(date: lastActive),
            "isActive": isActive,
            "participants": participants
        ]
        
        if let cloudKitRecordId = cloudKitRecordId {
            data["cloudKitRecordId"] = cloudKitRecordId
        }
        
        return data
    }
    
    static func fromFirestoreData(_ data: [String: Any]) throws -> Session {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let lastActiveTimestamp = data["lastActive"] as? Timestamp else {
            throw FirestoreError.invalidData("Missing required session fields")
        }
        
        let session = Session(name: name)
        session.id = id
        session.createdAt = createdAtTimestamp.dateValue()
        session.lastActive = lastActiveTimestamp.dateValue()
        session.isActive = data["isActive"] as? Bool ?? true
        session.participants = data["participants"] as? String ?? "[]"
        session.cloudKitRecordId = data["cloudKitRecordId"] as? String
        
        return session
    }
}

// MARK: - DevicePosition Firestore Extensions

extension DevicePosition {
    func toFirestoreData() throws -> [String: Any] {
        return [
            "id": id,
            "x": x,
            "y": y,
            "z": z,
            "rotation": rotation,
            "deviceId": deviceId,
            "sessionId": sessionId,
            "timestamp": Timestamp(date: timestamp)
        ]
    }
    
    static func fromFirestoreData(_ data: [String: Any]) throws -> DevicePosition {
        guard let id = data["id"] as? String,
              let x = data["x"] as? Double,
              let y = data["y"] as? Double,
              let z = data["z"] as? Double,
              let rotation = data["rotation"] as? Double,
              let deviceId = data["deviceId"] as? String,
              let sessionId = data["sessionId"] as? String,
              let timestamp = data["timestamp"] as? Timestamp else {
            throw FirestoreError.invalidData("Missing required device position fields")
        }
        
        let position = DevicePosition(
            x: x,
            y: y,
            z: z,
            rotation: rotation,
            deviceId: deviceId,
            sessionId: sessionId
        )
        
        position.id = id
        position.timestamp = timestamp.dateValue()
        
        return position
    }
}

// MARK: - Firestore Error

enum FirestoreError: LocalizedError {
    case invalidData(String)
    case encodingError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidData(let message):
            return "Invalid Firestore data: \(message)"
        case .encodingError(let error):
            return "Firestore encoding error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Firestore decoding error: \(error.localizedDescription)"
        }
    }
} 