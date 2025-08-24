import SwiftUI
import UIKit

@main
struct hastighedApp: App {
    init() {
        // Keep screen awake when app is running
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}