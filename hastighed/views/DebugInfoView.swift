import SwiftUI
import CoreLocation

struct DebugInfoView: View {
    @ObservedObject var locationManager: LocationManager
    var isCompact: Bool = false

    private var coordinateText: String {
        if let loc = locationManager.currentLocation {
            let lat = String(format: "%.6f", loc.coordinate.latitude)
            let lon = String(format: "%.6f", loc.coordinate.longitude)
            let acc = loc.horizontalAccuracy.isFinite ? String(format: "±%.0f m", loc.horizontalAccuracy) : ""
            return "GPS: \(lat), \(lon) \(acc)"
        }
        return "GPS: acquiring…"
    }

    private var addressText: String {
        let street = locationManager.currentStreetName
        return street.isEmpty ? "Address: acquiring…" : "Address: \(street)"
    }

    private var speedLimitText: String {
        if let limit = locationManager.currentSpeedLimit {
            return "Speed limit: \(limit) km/h"
        }
        return "Speed limit: detecting…"
    }

    var body: some View {
        Group {
            if isCompact {
                Text("\(coordinateText) • \(addressText) • \(speedLimitText)")
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(coordinateText)
                    Text(addressText)
                    Text(speedLimitText)
                }
            }
        }
        .font(.system(.footnote, design: .monospaced))
        .foregroundColor(.white)
        .padding(10)
        .background(
            isCompact
            ? AnyShapeStyle(Color.black.opacity(0.75))
            : AnyShapeStyle(.ultraThinMaterial)
        , in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(radius: 6)
        .padding(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Debug information: \(coordinateText). \(addressText). \(speedLimitText)."))
    }
}

#Preview {
    DebugInfoView(locationManager: LocationManager())
        .background(Color.black)
}
