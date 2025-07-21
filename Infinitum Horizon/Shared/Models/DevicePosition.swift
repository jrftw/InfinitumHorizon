import Foundation
import SwiftData

@Model
final class DevicePosition {
    var id: String = UUID().uuidString
    var x: Double = 0.0
    var y: Double = 0.0
    var z: Double = 0.0
    var rotation: Double = 0.0
    var deviceId: String = ""
    var sessionId: String = ""
    var timestamp: Date = Date()
    
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