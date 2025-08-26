import SwiftUI

struct SpeedDialDemoHarnessView: View {
    private var speedKmh: Double
    private var limitKmh: Double?
    private var units: SpeedUnits
    
    init() {
        let env = ProcessInfo.processInfo.environment
        if let s = env["SPEED_KMH"], let d = Double(s) { speedKmh = d } else { speedKmh = 0 }
        if let l = env["LIMIT_KMH"], let d = Double(l) { limitKmh = d } else { limitKmh = nil }
        if let u = env["UNITS"], let parsed = SpeedUnits(rawValue: u) { units = parsed } else { units = .kmh }
        UserDefaults.standard.set(units.rawValue, forKey: "speedUnits")
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            SpeedDialView(
                speedKmh: speedKmh,
                maxSpeedKmh: max(120, (limitKmh ?? 100) * 2),
                size: 260,
                batteryLevel: 0,
                speedLimitKmh: limitKmh
            )
        }
    }
}


