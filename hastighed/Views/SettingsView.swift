import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Top Speed")
                            Spacer()
                            Text(String(format: "%.0f %@", settings.displaySpeed(from: settings.topSpeedKmh), settings.speedUnitLabel))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(get: { settings.displaySpeed(from: settings.topSpeedKmh) }, set: { newVal in
                            settings.topSpeedKmh = settings.convertToKmh(from: newVal)
                        }), in: 60...360, step: 5)
                    }
                }
                Section("Measurement") {
                    Toggle(isOn: $settings.useImperialUnits) {
                        Text("Use mph (instead of km/h)")
                    }
                }
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
