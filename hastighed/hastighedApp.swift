import SwiftUI
import UIKit

@main
struct hastighedApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("keepScreenAwake") private var keepScreenAwake: Bool = true
    
    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.environment["UI_TEST_SPEEDDIAL_HARNESS"] == "1" {
                SpeedometerLiveHarnessView()
            } else if ProcessInfo.processInfo.environment["UI_TEST_HOME_SIGNS_HARNESS"] == "1" {
                let current = Int(ProcessInfo.processInfo.environment["CURRENT_LIMIT"] ?? "50") ?? 50
                let upcoming = Int(ProcessInfo.processInfo.environment["UPCOMING_LIMIT"] ?? "")
                HomeSignsHarnessView(currentLimit: current, upcomingLimit: upcoming)
            } else {
                ContentView()
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
            UIApplication.shared.isIdleTimerDisabled = (scenePhase == .active) && newValue
        }
    }
}