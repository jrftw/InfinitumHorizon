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
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
