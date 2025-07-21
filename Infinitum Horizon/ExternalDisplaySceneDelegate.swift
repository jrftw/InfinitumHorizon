import UIKit
import SwiftUI

class ExternalDisplaySceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // Create a simple external display view
        let externalDisplayView = ExternalDisplayView()
        let hostingController = UIHostingController(rootView: externalDisplayView)
        window.rootViewController = hostingController
        
        window.makeKeyAndVisible()
    }
}

struct ExternalDisplayView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "display.2")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("External Display")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Connected to external display")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
} 