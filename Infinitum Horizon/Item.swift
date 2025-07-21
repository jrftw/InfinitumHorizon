//
//  Item.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var id: String = UUID().uuidString
    var timestamp: Date = Date()
    
    init(timestamp: Date = Date()) {
        self.timestamp = timestamp
    }
}
