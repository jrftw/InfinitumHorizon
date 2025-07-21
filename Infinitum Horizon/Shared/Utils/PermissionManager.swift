import Foundation
import AVFoundation
import CoreLocation
import HealthKit
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

@MainActor
class PermissionManager: NSObject, ObservableObject {
    static let shared = PermissionManager()
    
    @Published var cameraPermission: AVAuthorizationStatus = .notDetermined
    @Published var microphonePermission: AVAuthorizationStatus = .notDetermined
    @Published var locationPermission: CLAuthorizationStatus = .notDetermined
    @Published var healthPermission: Bool = false
    
    private let locationManager = CLLocationManager()
    private let healthStore = HKHealthStore()
    
    private override init() {
        super.init()
        setupLocationManager()
        checkCurrentPermissions()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
    }
    
    private func checkCurrentPermissions() {
        cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        microphonePermission = AVCaptureDevice.authorizationStatus(for: .audio)
        locationPermission = locationManager.authorizationStatus
    }
    
    // MARK: - Camera Permission
    
    func requestCameraPermission() async -> Bool {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            cameraPermission = status ? .authorized : .denied
        }
        return status
    }
    
    // MARK: - Microphone Permission
    
    func requestMicrophonePermission() async -> Bool {
        let status = await AVCaptureDevice.requestAccess(for: .audio)
        await MainActor.run {
            microphonePermission = status ? .authorized : .denied
        }
        return status
    }
    
    // MARK: - Location Permission
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - Health Permission
    
    func requestHealthPermission() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            await MainActor.run {
                healthPermission = true
            }
            return true
        } catch {
            #if DEBUG
            print("Health permission error: \(error)")
            #endif
            return false
        }
    }
    
    // MARK: - Permission Status
    
    var hasCameraPermission: Bool {
        return cameraPermission == .authorized
    }
    
    var hasMicrophonePermission: Bool {
        return microphonePermission == .authorized
    }
    
    var hasLocationPermission: Bool {
        return locationPermission == .authorizedWhenInUse || locationPermission == .authorizedAlways
    }
    
    var hasHealthPermission: Bool {
        return healthPermission
    }
    
    // MARK: - Permission Descriptions
    
    func getPermissionDescription(for permission: PermissionType) -> String {
        switch permission {
        case .camera:
            return "Camera access is needed for AR features and device connectivity"
        case .microphone:
            return "Microphone access is needed for voice commands and audio communication"
        case .location:
            return "Location access is needed for device connectivity and location-based features"
        case .health:
            return "Health data access is needed for personalized insights and health features"
        }
    }
}

// MARK: - Permission Types
enum PermissionType {
    case camera
    case microphone
    case location
    case health
}

// MARK: - CLLocationManagerDelegate
extension PermissionManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            locationPermission = manager.authorizationStatus
        }
    }
} 