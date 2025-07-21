import Foundation
import SwiftData

@Model
final class Session {
    var id: String = UUID().uuidString
    var name: String = ""
    var createdAt: Date = Date()
    var lastActive: Date = Date()
    var isActive: Bool = true
    var participants: String = "[]" // JSON string storage for device IDs
    var cloudKitRecordId: String?
    
    init(name: String) {
        self.name = name
        self.createdAt = Date()
        self.lastActive = Date()
        self.isActive = true
        self.participants = "[]"
    }
} 