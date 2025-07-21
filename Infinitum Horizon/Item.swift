//
//  Item.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//  Updated 7/21/2025 by @jrftw
//
//  SwiftData model for basic Item entities
//  Serves as a simple test model for demonstrating SwiftData functionality
//  Used primarily for development and testing purposes
//

import Foundation
import SwiftData

// MARK: - Item Model
/// Basic SwiftData model for demonstration and testing purposes
/// Provides a simple entity with timestamp tracking for CRUD operations
/// SUGGESTION: This appears to be a placeholder model - consider expanding with more meaningful properties
@Model
final class Item {
    // MARK: - Properties
    /// Unique identifier for the item, auto-generated using UUID
    /// Used for SwiftData's internal tracking and relationship management
    var id: String = UUID().uuidString
    
    /// Timestamp when the item was created or last modified
    /// Provides temporal context for the item's lifecycle
    var timestamp: Date = Date()
    
    // MARK: - Initialization
    /// Creates a new Item instance with optional timestamp parameter
    /// Defaults to current date if no timestamp is provided
    /// SUGGESTION: Consider adding validation for timestamp values
    init(timestamp: Date = Date()) {
        self.timestamp = timestamp
    }
}
