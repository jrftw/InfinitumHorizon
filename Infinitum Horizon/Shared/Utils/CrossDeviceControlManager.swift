import Foundation
import MultipeerConnectivity
import Network
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

#if os(iOS) || os(watchOS)
import WatchConnectivity
#endif

@MainActor
class CrossDeviceControlManager: NSObject, ObservableObject {
    static let shared = CrossDeviceControlManager()
    
    // MARK: - Published Properties
    @Published var connectedDevices: [ConnectedDevice] = []
    @Published var isHosting = false
    @Published var isBrowsing = false
    @Published var receivedCommands: [DeviceCommand] = []
    @Published var lastError: String?
    
    // MARK: - Private Properties
    private let serviceType = "infinitum-ctrl"
    private let myPeerId: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    #if os(iOS) || os(watchOS)
    private var watchSession: WCSession?
    #endif
    
    private let commandQueue = DispatchQueue(label: "com.infinitumhorizon.commands", qos: .userInitiated)
    
    // MARK: - Initialization
    override init() {
        let deviceName: String
        #if os(iOS) || os(tvOS)
        deviceName = UIDevice.current.name
        #elseif os(macOS)
        deviceName = ProcessInfo.processInfo.hostName
        #elseif os(watchOS)
        deviceName = WKInterfaceDevice.current().name
        #elseif os(visionOS)
        deviceName = UIDevice.current.name
        #else
        deviceName = "Unknown Device"
        #endif
        
        self.myPeerId = MCPeerID(displayName: deviceName)
        super.init()
        
        setupWatchConnectivity()
    }
    
    // MARK: - Device Control Methods
    
    // MARK: App Launching / Deep Linking
    func launchAppOnDevice(_ deviceId: String, appURL: URL, completion: @escaping (Bool) -> Void) {
        let command = DeviceCommand(
            type: .launchApp,
            targetDevice: deviceId,
            data: ["url": appURL.absoluteString],
            timestamp: Date()
        )
        
        sendCommand(command) { success in
            completion(success)
        }
    }
    
    func openURLOnDevice(_ deviceId: String, url: URL, completion: @escaping (Bool) -> Void) {
        let command = DeviceCommand(
            type: .openURL,
            targetDevice: deviceId,
            data: ["url": url.absoluteString],
            timestamp: Date()
        )
        
        sendCommand(command) { success in
            completion(success)
        }
    }
    
    // MARK: Watch Control
    func sendHapticToWatch(_ hapticType: WatchHapticType) {
        #if os(iOS)
        guard let watchSession = watchSession, watchSession.isReachable else {
            lastError = "Apple Watch not reachable"
            return
        }
        
        let command = DeviceCommand(
            type: .watchHaptic,
            targetDevice: "AppleWatch",
            data: ["hapticType": hapticType.rawValue],
            timestamp: Date()
        )
        
        sendWatchCommand(command)
        #endif
    }
    
    func startWorkoutOnWatch(workoutType: String, completion: @escaping (Bool) -> Void) {
        let command = DeviceCommand(
            type: .startWorkout,
            targetDevice: "AppleWatch",
            data: ["workoutType": workoutType],
            timestamp: Date()
        )
        
        sendCommand(command) { success in
            completion(success)
        }
    }
    
    func stopWorkoutOnWatch(completion: @escaping (Bool) -> Void) {
        let command = DeviceCommand(
            type: .stopWorkout,
            targetDevice: "AppleWatch",
            data: [:],
            timestamp: Date()
        )
        
        sendCommand(command) { success in
            completion(success)
        }
    }
    
    // MARK: Mac Control
    func executeAppleScriptOnMac(_ script: String, completion: @escaping (Bool) -> Void) {
        let command = DeviceCommand(
            type: .executeScript,
            targetDevice: "Mac",
            data: ["script": script],
            timestamp: Date()
        )
        
        sendCommand(command) { success in
            completion(success)
        }
    }
    
    func openAppOnMac(_ appName: String, completion: @escaping (Bool) -> Void) {
        let command = DeviceCommand(
            type: .openMacApp,
            targetDevice: "Mac",
            data: ["appName": appName],
            timestamp: Date()
        )
        
        sendCommand(command) { success in
            completion(success)
        }
    }
    
    // MARK: Vision Pro Control
    func changeVisionProLayout(_ layout: VisionProLayout, completion: @escaping (Bool) -> Void) {
        let command = DeviceCommand(
            type: .changeLayout,
            targetDevice: "VisionPro",
            data: ["layout": layout.rawValue],
            timestamp: Date()
        )
        
        sendCommand(command) { success in
            completion(success)
        }
    }
    
    func controlImmersiveElement(_ elementId: String, action: String, completion: @escaping (Bool) -> Void) {
        let command = DeviceCommand(
            type: .controlImmersive,
            targetDevice: "VisionPro",
            data: ["elementId": elementId, "action": action],
            timestamp: Date()
        )
        
        sendCommand(command) { success in
            completion(success)
        }
    }
    
    // MARK: iPad Dashboard Control
    func updateDashboardOniPad(_ dashboardData: [String: Any], completion: @escaping (Bool) -> Void) {
        let command = DeviceCommand(
            type: .updateDashboard,
            targetDevice: "iPad",
            data: dashboardData,
            timestamp: Date()
        )
        
        sendCommand(command) { success in
            completion(success)
        }
    }
    
    // MARK: - Connection Management
    
    func startHosting() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        isHosting = true
    }
    
    func startBrowsing() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        isBrowsing = true
    }
    
    func disconnect() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        
        browser?.stopBrowsingForPeers()
        browser = nil
        
        session?.disconnect()
        session = nil
        
        connectedDevices.removeAll()
        isHosting = false
        isBrowsing = false
    }
    
    // MARK: - Private Methods
    
    private func setupWatchConnectivity() {
        #if os(iOS) || os(watchOS)
        if WCSession.isSupported() {
            watchSession = WCSession.default
            watchSession?.delegate = self
            watchSession?.activate()
        }
        #endif
    }
    
    private func sendCommand(_ command: DeviceCommand, completion: @escaping (Bool) -> Void) {
        guard let session = session, !session.connectedPeers.isEmpty else {
            completion(false)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(command)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            completion(true)
        } catch {
            lastError = "Failed to send command: \(error.localizedDescription)"
            completion(false)
        }
    }
    
    private func sendWatchCommand(_ command: DeviceCommand) {
        #if os(iOS)
        guard let watchSession = watchSession, watchSession.isReachable else { return }
        
        do {
            let data = try JSONEncoder().encode(command)
            watchSession.sendMessageData(data, replyHandler: nil) { error in
                self.lastError = "Watch command failed: \(error.localizedDescription)"
            }
        } catch {
            lastError = "Failed to encode watch command: \(error.localizedDescription)"
        }
        #endif
    }
    
    private func handleReceivedCommand(_ command: DeviceCommand) {
        DispatchQueue.main.async {
            self.receivedCommands.append(command)
        }
        
        // Execute command based on type
        executeCommand(command)
    }
    
    private func executeCommand(_ command: DeviceCommand) {
        switch command.type {
        case .launchApp:
            if let urlString = command.data["url"] as? String,
               let url = URL(string: urlString) {
                #if os(iOS) || os(tvOS)
                UIApplication.shared.open(url)
                #elseif os(macOS)
                NSWorkspace.shared.open(url)
                #endif
            }
            
        case .openURL:
            if let urlString = command.data["url"] as? String,
               let url = URL(string: urlString) {
                #if os(iOS) || os(tvOS)
                UIApplication.shared.open(url)
                #elseif os(macOS)
                NSWorkspace.shared.open(url)
                #endif
            }
            
        case .watchHaptic:
            #if os(watchOS)
            if let hapticTypeString = command.data["hapticType"] as? String,
               let hapticType = WatchHapticType(rawValue: hapticTypeString) {
                WKInterfaceDevice.current().play(hapticType.watchHaptic)
            }
            #endif
            
        case .startWorkout:
            // Handle workout start
            break
            
        case .stopWorkout:
            // Handle workout stop
            break
            
        case .executeScript:
            #if os(macOS)
            if let script = command.data["script"] as? String {
                executeAppleScript(script)
            }
            #endif
            
        case .openMacApp:
            #if os(macOS)
            if let appName = command.data["appName"] as? String {
                NSWorkspace.shared.launchApplication(appName)
            }
            #endif
            
        case .changeLayout:
            // Handle Vision Pro layout change
            break
            
        case .controlImmersive:
            // Handle immersive element control
            break
            
        case .updateDashboard:
            // Handle dashboard update
            break
        }
    }
    
    #if os(macOS)
    private func executeAppleScript(_ script: String) {
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)
        
        if let error = error {
            lastError = "AppleScript error: \(error)"
        }
    }
    #endif
    
    deinit {
        Task { @MainActor [weak self] in
            self?.disconnect()
        }
    }
}

// MARK: - MCSessionDelegate
extension CrossDeviceControlManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                let device = ConnectedDevice(
                    peerId: peerID,
                    deviceType: self.detectDeviceType(from: peerID.displayName),
                    isReachable: true
                )
                if !self.connectedDevices.contains(device) {
                    self.connectedDevices.append(device)
                }
            case .notConnected:
                self.connectedDevices.removeAll { $0.peerId == peerID }
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            do {
                let command = try JSONDecoder().decode(DeviceCommand.self, from: data)
                self.handleReceivedCommand(command)
            } catch {
                self.lastError = "Failed to decode command: \(error.localizedDescription)"
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension CrossDeviceControlManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension CrossDeviceControlManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            guard let session = self.session else {
                #if DEBUG
                print("Error: Session is nil when trying to invite peer")
                #endif
                return
            }
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // Handle lost peer
    }
}

// MARK: - WCSessionDelegate
#if os(iOS) || os(watchOS)
extension CrossDeviceControlManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                self.lastError = "Watch session activation failed: \(error.localizedDescription)"
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        Task { @MainActor in
            do {
                let command = try JSONDecoder().decode(DeviceCommand.self, from: messageData)
                self.handleReceivedCommand(command)
            } catch {
                self.lastError = "Failed to decode watch command: \(error.localizedDescription)"
            }
        }
    }
    
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
    
    #if os(watchOS)
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                self.lastError = "Watch session activation failed: \(error.localizedDescription)"
            }
        }
    }
    #endif
}
#endif

// MARK: - Helper Methods
extension CrossDeviceControlManager {
    private func detectDeviceType(from deviceName: String) -> DeviceType {
        let lowercasedName = deviceName.lowercased()
        
        if lowercasedName.contains("iphone") {
            return .iPhone
        } else if lowercasedName.contains("ipad") {
            return .iPad
        } else if lowercasedName.contains("mac") || lowercasedName.contains("imac") || lowercasedName.contains("macbook") {
            return .Mac
        } else if lowercasedName.contains("watch") {
            return .AppleWatch
        } else if lowercasedName.contains("vision") || lowercasedName.contains("pro") {
            return .VisionPro
        } else if lowercasedName.contains("tv") {
            return .AppleTV
        } else {
            return .iPhone // Default fallback
        }
    }
}

// MARK: - Supporting Types

struct ConnectedDevice: Identifiable, Hashable {
    let id = UUID()
    let peerId: MCPeerID
    let deviceType: DeviceType
    let isReachable: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(peerId)
    }
    
    static func == (lhs: ConnectedDevice, rhs: ConnectedDevice) -> Bool {
        return lhs.peerId == rhs.peerId
    }
}

enum DeviceType: String, CaseIterable {
    case iPhone = "iPhone"
    case iPad = "iPad"
    case Mac = "Mac"
    case AppleWatch = "AppleWatch"
    case VisionPro = "VisionPro"
    case AppleTV = "AppleTV"
}

struct DeviceCommand: Codable, Identifiable {
    let id = UUID()
    let type: CommandType
    let targetDevice: String
    let data: [String: Any]
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case type, targetDevice, data, timestamp
    }
    
    init(type: CommandType, targetDevice: String, data: [String: Any], timestamp: Date) {
        self.type = type
        self.targetDevice = targetDevice
        self.data = data
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(CommandType.self, forKey: .type)
        targetDevice = try container.decode(String.self, forKey: .targetDevice)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Handle [String: Any] decoding
        let dataContainer = try container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .data)
        var tempData: [String: Any] = [:]
        for key in dataContainer.allKeys {
            if let value = try? dataContainer.decode(String.self, forKey: key) {
                tempData[key.stringValue] = value
            } else if let value = try? dataContainer.decode(Int.self, forKey: key) {
                tempData[key.stringValue] = value
            } else if let value = try? dataContainer.decode(Double.self, forKey: key) {
                tempData[key.stringValue] = value
            } else if let value = try? dataContainer.decode(Bool.self, forKey: key) {
                tempData[key.stringValue] = value
            }
        }
        data = tempData
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(targetDevice, forKey: .targetDevice)
        try container.encode(timestamp, forKey: .timestamp)
        
        // Handle [String: Any] encoding
        var dataContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .data)
        for (key, value) in data {
            let codingKey = DynamicCodingKeys(stringValue: key)!
            if let stringValue = value as? String {
                try dataContainer.encode(stringValue, forKey: codingKey)
            } else if let intValue = value as? Int {
                try dataContainer.encode(intValue, forKey: codingKey)
            } else if let doubleValue = value as? Double {
                try dataContainer.encode(doubleValue, forKey: codingKey)
            } else if let boolValue = value as? Bool {
                try dataContainer.encode(boolValue, forKey: codingKey)
            }
        }
    }
}

enum CommandType: String, Codable, CaseIterable {
    case launchApp = "launchApp"
    case openURL = "openURL"
    case watchHaptic = "watchHaptic"
    case startWorkout = "startWorkout"
    case stopWorkout = "stopWorkout"
    case executeScript = "executeScript"
    case openMacApp = "openMacApp"
    case changeLayout = "changeLayout"
    case controlImmersive = "controlImmersive"
    case updateDashboard = "updateDashboard"
}

enum WatchHapticType: String, CaseIterable {
    case notification = "notification"
    case directionUp = "directionUp"
    case directionDown = "directionDown"
    case success = "success"
    case failure = "failure"
    case retry = "retry"
    case start = "start"
    case stop = "stop"
    case click = "click"
    
    #if os(watchOS)
    var watchHaptic: WKHapticType {
        switch self {
        case .notification: return .notification
        case .directionUp: return .directionUp
        case .directionDown: return .directionDown
        case .success: return .success
        case .failure: return .failure
        case .retry: return .retry
        case .start: return .start
        case .stop: return .stop
        case .click: return .click
        }
    }
    #endif
}

enum VisionProLayout: String, CaseIterable {
    case immersive = "immersive"
    case mixed = "mixed"
    case windowed = "windowed"
    case fullscreen = "fullscreen"
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
} 