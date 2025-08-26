import SwiftUI
import UIKit

@main
struct hastighedApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("keepScreenAwake") private var keepScreenAwake: Bool = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if ProcessInfo.processInfo.environment["UI_TEST_SPEEDDIAL_HARNESS"] == "1" {
                    SpeedDialDemoHarnessView()
                } else {
                    ContentView()
                }
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = keepScreenAwake
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                UIApplication.shared.isIdleTimerDisabled = keepScreenAwake
            } else {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
        .onChange(of: keepScreenAwake) { _, newValue in
            // Apply immediately if active
            UIApplication.shared.isIdleTimerDisabled = (scenePhase == .active) && newValue
        }
    }
}