import SwiftUI
import CoreLocation

struct DebugSnapshot {
    let speed: Measurement<UnitSpeed>?
    let coordinate: CLLocationCoordinate2D?
    let speedLimit: SpeedLimit?
    let unitLabel: String
}

struct DebugOverlayView: View {
    let snapshot: DebugSnapshot

    private var speedText: String {
        guard let s = snapshot.speed else { return "--" }
        return String(format: "%.0f %@", s.value, snapshot.unitLabel)
    }

    private var coordText: String {
        guard let c = snapshot.coordinate else { return "--" }
        return String(format: "%.5f, %.5f", c.latitude, c.longitude)
    }

    private var limitText: String {
        guard let l = snapshot.speedLimit else { return "--" }
        return String(format: "%.0f %@", l.value.value, snapshot.unitLabel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text("Speed:"); Spacer(); Text(speedText).monospacedDigit() }
            HStack { Text("GPS:"); Spacer(); Text(coordText).monospacedDigit() }
            HStack { Text("Limit:"); Spacer(); Text(limitText).monospacedDigit() }
        }
        .font(.caption)
        .padding(12)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding()
    }
}

#Preview {
    DebugOverlayView(snapshot: DebugSnapshot(
        speed: Measurement(value: 72, unit: .kilometersPerHour),
        coordinate: CLLocationCoordinate2D(latitude: 55.6761, longitude: 12.5683),
        speedLimit: SpeedLimit(kmh: 50, source: .ruleFallback, confidence: 0.5),
        unitLabel: AppConstants.speedUnitLabel
    ))
    .preferredColorScheme(.dark)
}


