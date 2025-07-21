//
//  Session.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//  Updated 7/21/2025 by @jrftw
//
//  SwiftData model for Session entities
//  Manages collaborative sessions across multiple devices and platforms
//  Handles session lifecycle, participant tracking, and CloudKit synchronization
//

import Foundation
import SwiftData

// MARK: - Session Model
/// Represents a collaborative session that can span multiple devices and platforms
/// Manages session state, participant tracking, and cross-device synchronization
/// Integrates with CloudKit for cloud-based session persistence
@Model
final class Session {
    // MARK: - Core Properties
    /// Unique identifier for the session, auto-generated using UUID
    /// Used for SwiftData relationships and CloudKit record identification
    var id: String = UUID().uuidString
    
    /// Human-readable name for the session
    /// Displayed in UI for session identification and management
    var name: String = ""
    
    /// Timestamp when the session was created
    /// Used for session age calculations and cleanup operations
    var createdAt: Date = Date()
    
    /// Timestamp of the last activity in the session
    /// Updated when participants interact with the session
    var lastActive: Date = Date()
    
    /// Indicates whether the session is currently active
    /// Used to determine if session should be displayed and synchronized
    var isActive: Bool = true
    
    /// JSON string containing array of participant device IDs
    /// Flexible storage for tracking which devices are part of the session
    /// SUGGESTION: Consider using a proper relationship model instead of JSON string
    var participants: String = "[]" // JSON string storage for device IDs
    
    /// CloudKit record identifier for cloud synchronization
    /// Used to link local SwiftData record with CloudKit record
    var cloudKitRecordId: String?
    
    // MARK: - Initialization
    /// Creates a new Session instance with the specified name
    /// Sets up default values for all session properties
    /// SUGGESTION: Consider adding validation for session name requirements
    init(name: String) {
        self.name = name
        self.createdAt = Date()
        self.lastActive = Date()
        self.isActive = true
        self.participants = "[]"
    }
} 