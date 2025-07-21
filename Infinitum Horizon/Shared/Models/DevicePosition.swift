//
//  DevicePosition.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//  Updated 7/21/2025 by @jrftw
//
//  SwiftData model for DevicePosition entities
//  Tracks 3D spatial positioning and orientation of devices in collaborative sessions
//  Enables cross-device spatial awareness and positioning synchronization
//

import Foundation
import SwiftData

// MARK: - Device Position Model
/// Represents the 3D spatial position and orientation of a device in a collaborative session
/// Enables cross-device spatial awareness and positioning for multi-device experiences
/// Used for visionOS spatial computing and cross-platform device positioning
@Model
final class DevicePosition {
    // MARK: - Core Properties
    /// Unique identifier for the position record, auto-generated using UUID
    /// Used for SwiftData relationships and position tracking
    var id: String = UUID().uuidString
    
    /// X-coordinate position in 3D space
    /// Represents horizontal position relative to session origin
    var x: Double = 0.0
    
    /// Y-coordinate position in 3D space
    /// Represents vertical position relative to session origin
    var y: Double = 0.0
    
    /// Z-coordinate position in 3D space
    /// Represents depth position relative to session origin
    var z: Double = 0.0
    
    /// Rotation angle around the Y-axis (up/down axis)
    /// Represents device orientation in degrees (0-360)
    var rotation: Double = 0.0
    
    /// Unique identifier of the device this position belongs to
    /// Links position data to specific device for tracking
    var deviceId: String = ""
    
    /// Unique identifier of the session this position belongs to
    /// Links position data to specific collaborative session
    var sessionId: String = ""
    
    /// Timestamp when this position was recorded
    /// Used for temporal tracking and position history
    var timestamp: Date = Date()
    
    // MARK: - Initialization
    /// Creates a new DevicePosition instance with 3D coordinates and device information
    /// Sets up position tracking for cross-device spatial awareness
    /// SUGGESTION: Consider adding validation for coordinate ranges and device/session IDs
    init(x: Double, y: Double, z: Double, rotation: Double, deviceId: String, sessionId: String) {
        self.x = x
        self.y = y
        self.z = z
        self.rotation = rotation
        self.deviceId = deviceId
        self.sessionId = sessionId
        self.timestamp = Date()
    }
} 