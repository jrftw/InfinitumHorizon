//
//  AppVersionManager.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//  Updated 7/21/2025 by @jrftw
//
//  Utility classes for app version management, logging, and theme management
//  Provides centralized logging, theme control, and version information across the app
//  Includes environment detection and changelog management
//

import Foundation
import SwiftUI
import os.log
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

// MARK: - Production Logging System
/// Centralized logging system using Apple's unified logging framework
/// Provides structured logging with privacy controls and debug/release filtering
/// Used throughout the app for consistent logging and debugging
class AppLogger {
    /// Shared singleton instance for app-wide logging access
    static let shared = AppLogger()
    
    /// Unified logger instance with app-specific subsystem and category
    private let logger = Logger(subsystem: "com.infinitumhorizon.app", category: "main")
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Logs debug messages (only in DEBUG builds)
    /// Used for detailed debugging information during development
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        logger.debug("\(message, privacy: .public)")
        #endif
    }
    
    /// Logs informational messages
    /// Used for general app flow and user actions
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.info("\(message, privacy: .public)")
    }
    
    /// Logs warning messages
    /// Used for non-critical issues that should be monitored
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.warning("\(message, privacy: .public)")
    }
    
    /// Logs error messages
    /// Used for recoverable errors and issues
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.error("\(message, privacy: .public)")
    }
    
    /// Logs fault messages (highest severity)
    /// Used for critical errors and system failures
    func fault(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.fault("\(message, privacy: .public)")
    }
}

// MARK: - Theme Manager
/// Manages app-wide theme and appearance settings
/// Provides light, dark, and auto theme modes with persistence
/// Integrates with SwiftUI's color scheme system
class ThemeManager: ObservableObject {
    /// Shared singleton instance for app-wide theme access
    static let shared = ThemeManager()
    
    /// Current color scheme for SwiftUI integration
    @Published var colorScheme: ColorScheme? = nil
    
    /// Current theme mode setting
    @Published var themeMode: ThemeMode = .auto
    
    /// Available theme modes with descriptions and icons
    enum ThemeMode: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case auto = "Auto"
        
        /// SF Symbol icon for each theme mode
        var icon: String {
            switch self {
            case .light:
                return "sun.max.fill"
            case .dark:
                return "moon.fill"
            case .auto:
                return "gear"
            }
        }
        
        /// Human-readable description for UI display
        var description: String {
            switch self {
            case .light:
                return "Always use light appearance"
            case .dark:
                return "Always use dark appearance"
            case .auto:
                return "Follow system appearance"
            }
        }
    }
    
    /// Private initializer that loads saved theme settings
    private init() {
        loadThemeSettings()
    }
    
    /// Loads theme settings from UserDefaults
    /// Restores user's previous theme preference
    private func loadThemeSettings() {
        if let savedMode = UserDefaults.standard.string(forKey: "themeMode"),
           let mode = ThemeMode(rawValue: savedMode) {
            themeMode = mode
        }
        updateColorScheme()
    }
    
    /// Sets new theme mode and persists to UserDefaults
    /// Updates color scheme immediately
    func setThemeMode(_ mode: ThemeMode) {
        themeMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "themeMode")
        updateColorScheme()
    }
    
    /// Updates color scheme based on current theme mode
    /// Handles auto mode by setting to nil for system decision
    private func updateColorScheme() {
        switch themeMode {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .auto:
            colorScheme = nil // Let system decide
        }
    }
}

// MARK: - App Version Manager
/// Manages app version information, environment detection, and changelog
/// Provides version strings, build information, and environment-specific behavior
/// Used for debugging, support, and user information
class AppVersionManager: ObservableObject {
    /// Shared singleton instance for app-wide version access
    static let shared = AppVersionManager()
    
    /// Current app version string (e.g., "1.0")
    @Published var versionString: String = ""
    
    /// Current build number string (e.g., "1")
    @Published var buildString: String = ""
    
    /// Environment identifier (Dev, Beta, or empty for App Store)
    @Published var environmentString: String = ""
    
    /// Indicates if running in iOS Simulator
    @Published var isSimulator: Bool = false
    
    /// Indicates if running from TestFlight
    @Published var isTestFlight: Bool = false
    
    /// Indicates if running from App Store
    @Published var isAppStore: Bool = false
    
    /// Private initializer that sets up version information
    private init() {
        setupVersionInfo()
    }
    
    /// Sets up version information and detects environment
    /// Reads from Bundle and determines distribution method
    private func setupVersionInfo() {
        // Get version and build info from app bundle
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        // Detect environment based on build configuration and receipt
        #if targetEnvironment(simulator)
        isSimulator = true
        environmentString = "Dev"
        versionString = "\(version) (\(environmentString))"
        buildString = "Build \(build)"
        #else
        // Check if running from TestFlight by examining receipt
        if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
            isTestFlight = true
            environmentString = "Beta"
            versionString = "\(version) (\(environmentString))"
            buildString = "Build \(build)"
        } else {
            isAppStore = true
            environmentString = ""
            versionString = version
            buildString = "Build \(build)"
        }
        #endif
    }
    
    /// Complete version string for display
    /// Includes environment and build information as appropriate
    var fullVersionString: String {
        if isSimulator {
            return "\(versionString) - \(buildString)"
        } else if isTestFlight {
            return "\(versionString) - \(buildString)"
        } else {
            return "\(versionString) \(buildString)"
        }
    }
    
    /// App changelog with version history and feature descriptions
    /// Used for in-app changelog display and support documentation
    var changelog: [ChangelogEntry] {
        return [
            ChangelogEntry(version: "1.0", build: "1", date: "2025-01-20", changes: [
                "Initial release with iOS 26 design system",
                "Support for iPhone, iPad, Apple TV, and visionOS",
                "Multipeer connectivity features",
                "CloudKit integration",
                "Premium subscription system",
                "Modern glassy UI with SF Symbols 7",
                "Enhanced accessibility features",
                "Cross-platform data synchronization"
            ]),
            ChangelogEntry(version: "1.0", build: "2", date: "2025-01-21", changes: [
                "Added Apple TV support",
                "Improved visionOS status bar",
                "Enhanced battery monitoring",
                "Updated to latest iOS 26 design resources",
                "Fixed multipeer connectivity issues",
                "Improved performance and stability"
            ]),
            ChangelogEntry(version: "1.0", build: "3", date: "2025-01-22", changes: [
                "Added comprehensive dark mode support",
                "Enhanced theme management system",
                "Improved UI consistency across platforms",
                "Added auto theme detection",
                "Enhanced accessibility features",
                "Improved navigation and user experience"
            ])
        ]
    }
}

// MARK: - Changelog Entry Model
/// Represents a single changelog entry with version information
/// Used for displaying app update history and feature descriptions
struct ChangelogEntry: Identifiable {
    /// Unique identifier for SwiftUI list rendering
    let id = UUID()
    
    /// Version number (e.g., "1.0")
    let version: String
    
    /// Build number (e.g., "1")
    let build: String
    
    /// Release date in string format
    let date: String
    
    /// Array of change descriptions for this version
    let changes: [String]
    
    /// Combined version and build string for display
    var versionString: String {
        return "\(version) Build \(build)"
    }
} 