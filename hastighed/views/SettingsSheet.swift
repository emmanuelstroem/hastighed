import SwiftUI

struct SettingsSheet: View {
    @Binding var showDebugOverlay: Bool
    @Binding var showSpeedometer: Bool
    @Binding var showSpeedLimitSign: Bool
    @AppStorage("maxSpeedKmh") private var maxSpeedKmh: Double = 201

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Display")) {
                    Toggle("Speedometer", isOn: $showSpeedometer)
                    Toggle("Speed limit sign", isOn: $showSpeedLimitSign)
                    HStack {
                        Stepper("Max speed: \(Int(maxSpeedKmh)) km/h", value: $maxSpeedKmh, in: 60...360, step: 1)
                    }
                }
                Section(header: Text("Debug")) {
                    Toggle("Show debug overlay", isOn: $showDebugOverlay)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsSheet(showDebugOverlay: .constant(true), showSpeedometer: .constant(true), showSpeedLimitSign: .constant(true))
}
