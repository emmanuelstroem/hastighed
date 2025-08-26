import SwiftUI

struct SettingsSheet: View {
    @Binding var showDebugOverlay: Bool
    @Binding var showSpeedometer: Bool
    @Binding var showSpeedLimitSign: Bool
    @Binding var showStreetName: Bool
    @AppStorage("maxSpeedKmh") private var maxSpeedKmh: Double = 201
    @AppStorage("keepScreenAwake") private var keepScreenAwake: Bool = true
    @AppStorage("speedUnits") private var speedUnitsRaw: String = SpeedUnits.kmh.rawValue
    private var speedUnits: Binding<SpeedUnits> {
        Binding<SpeedUnits>(
            get: { SpeedUnits(rawValue: speedUnitsRaw) ?? .kmh },
            set: { speedUnitsRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Display")) {
                    Toggle("Speedometer", isOn: $showSpeedometer)
                    Toggle("Speed limit sign", isOn: $showSpeedLimitSign)
                    Toggle("Street name", isOn: $showStreetName)
                    Picker("Units", selection: speedUnits) {
                        ForEach(SpeedUnits.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    HStack {
                        Stepper("Max speed: \(Int(maxSpeedKmh)) km/h", value: $maxSpeedKmh, in: 60...360, step: 1)
                    }
                }
                Section(header: Text("Debug")) {
                    Toggle("Show debug overlay", isOn: $showDebugOverlay)
                }
                Section(header: Text("Power")) {
                    Toggle("Keep screen awake", isOn: $keepScreenAwake)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsSheet(showDebugOverlay: .constant(true), showSpeedometer: .constant(true), showSpeedLimitSign: .constant(true), showStreetName: .constant(true))
}
