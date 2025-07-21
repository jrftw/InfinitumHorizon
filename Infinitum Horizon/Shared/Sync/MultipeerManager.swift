import Foundation
import MultipeerConnectivity
import Combine
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

class MultipeerManager: NSObject, ObservableObject {
    static let shared = MultipeerManager()
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var isHosting = false
    @Published var isBrowsing = false
    @Published var receivedMessages: [String] = []
    
    private let serviceType = "infinitum-hor"
    private let myPeerId: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
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
    }
    
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
    
    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isHosting = false
    }
    
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        isBrowsing = false
    }
    
    func disconnect() {
        // Stop advertising and browsing
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        
        browser?.stopBrowsingForPeers()
        browser = nil
        
        // Disconnect session
        session?.disconnect()
        session = nil
        
        // Clear connected peers
        connectedPeers.removeAll()
        
        // Update state
        isHosting = false
        isBrowsing = false
    }
    
    deinit {
        disconnect()
    }
    
    func sendMessage(_ message: String) {
        guard let session = session,
              !session.connectedPeers.isEmpty,
              let data = message.data(using: .utf8) else { return }
        
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            #if DEBUG
            print("Error sending message: \(error)")
            #endif
        }
    }
    
    func sendDevicePosition(x: Double, y: Double, z: Double, rotation: Double) {
        let positionData = [
            "type": "position",
            "x": x,
            "y": y,
            "z": z,
            "rotation": rotation,
            "deviceId": myPeerId.displayName
        ] as [String: Any]
        
        if let data = try? JSONSerialization.data(withJSONObject: positionData) {
            do {
                try session?.send(data, toPeers: session?.connectedPeers ?? [], with: .unreliable)
            } catch {
                #if DEBUG
                print("Error sending position: \(error)")
                #endif
            }
        }
    }
}

// MARK: - MCSessionDelegate
extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            if let message = String(data: data, encoding: .utf8) {
                self.receivedMessages.append("\(peerID.displayName): \(message)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard let session = session else {
            #if DEBUG
            print("Error: Session is nil when trying to invite peer")
            #endif
            return
        }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // Handle lost peer
    }
} 