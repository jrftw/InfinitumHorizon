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
class AppLogger {
    static let shared = AppLogger()
    
    private let logger = Logger(subsystem: "com.infinitumhorizon.app", category: "main")
    
    private init() {}
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        logger.debug("\(message, privacy: .public)")
        #endif
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.info("\(message, privacy: .public)")
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.warning("\(message, privacy: .public)")
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.error("\(message, privacy: .public)")
    }
    
    func fault(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.fault("\(message, privacy: .public)")
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var colorScheme: ColorScheme? = nil
    @Published var themeMode: ThemeMode = .auto
    
    enum ThemeMode: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case auto = "Auto"
        
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
    
    private init() {
        loadThemeSettings()
    }
    
    private func loadThemeSettings() {
        if let savedMode = UserDefaults.standard.string(forKey: "themeMode"),
           let mode = ThemeMode(rawValue: savedMode) {
            themeMode = mode
        }
        updateColorScheme()
    }
    
    func setThemeMode(_ mode: ThemeMode) {
        themeMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "themeMode")
        updateColorScheme()
    }
    
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
class AppVersionManager: ObservableObject {
    static let shared = AppVersionManager()
    
    @Published var versionString: String = ""
    @Published var buildString: String = ""
    @Published var environmentString: String = ""
    @Published var isSimulator: Bool = false
    @Published var isTestFlight: Bool = false
    @Published var isAppStore: Bool = false
    
    private init() {
        setupVersionInfo()
    }
    
    private func setupVersionInfo() {
        // Get version and build info
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        // Detect environment
        #if targetEnvironment(simulator)
        isSimulator = true
        environmentString = "Dev"
        versionString = "\(version) (\(environmentString))"
        buildString = "Build \(build)"
        #else
        // Check if running from TestFlight
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
    
    var fullVersionString: String {
        if isSimulator {
            return "\(versionString) - \(buildString)"
        } else if isTestFlight {
            return "\(versionString) - \(buildString)"
        } else {
            return "\(versionString) \(buildString)"
        }
    }
    
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

struct ChangelogEntry: Identifiable {
    let id = UUID()
    let version: String
    let build: String
    let date: String
    let changes: [String]
    
    var versionString: String {
        return "\(version) Build \(build)"
    }
} 