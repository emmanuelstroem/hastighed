import SwiftUI

struct SettingsSheet: View {
    @Binding var showDebugOverlay: Bool
    @Binding var showSpeedometer: Bool
    @Binding var showSpeedLimitSign: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Display")) {
                    Toggle("Speedometer", isOn: $showSpeedometer)
                    Toggle("Speed limit sign", isOn: $showSpeedLimitSign)
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
