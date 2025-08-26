import SwiftUI
import UIKit

@main
struct hastighedApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("keepScreenAwake") private var keepScreenAwake: Bool = true
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = keepScreenAwake
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                UIApplication.shared.isIdleTimerDisabled = keepScreenAwake
            } else {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
        .onChange(of: keepScreenAwake) { newValue in
            // Apply immediately if active
            UIApplication.shared.isIdleTimerDisabled = (scenePhase == .active) && newValue
        }
    }
}