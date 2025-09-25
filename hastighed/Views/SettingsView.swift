import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @State private var offlineMapsViewModel = OfflineMapsViewModel(downloadService: DownloadService())
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Top Speed")
                            Spacer()
                            Text(String(format: "%.0f %@", settings.displaySpeed(from: settings.vehicleTopSpeed), settings.speedUnitLabel))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(get: { settings.displaySpeed(from: settings.vehicleTopSpeed) }, set: { newVal in
                            settings.vehicleTopSpeed = settings.convertToKmh(from: newVal)
                        }), in: 60...360, step: 5)
                    }
                }
                Section("Debug") {
                    Toggle(isOn: $settings.isDebugOverlayEnabled) {
                        Text("Debug Overlay")
                    }
                    .accessibilityIdentifier("toggle.debugOverlay")
                }
                Section("Visibility") {
                    Toggle(isOn: $settings.showGauge) { Text("Speedometer / Gauge") }
                        .accessibilityIdentifier("toggle.showGauge")
                    Toggle(isOn: $settings.showSpeedLimit) { Text("Speed Limit") }
                        .accessibilityIdentifier("toggle.showSpeedLimit")
                    Toggle(isOn: $settings.showSpeedCameras) { Text("Speed Cameras") }
                        .accessibilityIdentifier("toggle.showSpeedCameras")
                    Toggle(isOn: $settings.showHazards) { Text("Hazards") }
                        .accessibilityIdentifier("toggle.showHazards")
                }
                OfflineMapsSectionView(viewModel: offlineMapsViewModel)
                Section(footer: Text("Changes persist automatically using App Storage.")) { EmptyView() }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}

#Preview {
    SettingsView(settings: SettingsStore())
}
