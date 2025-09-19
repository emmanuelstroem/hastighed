import SwiftUI

struct SpeedCameraRowView: View {
    let camera: SpeedCamera
    let distanceFormatter: (Double) -> String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "camera.fill")
            Text(camera.typeLabel)
                .font(.headline)
            Spacer()
            Text(distanceFormatter(camera.distanceMeters))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

private extension SpeedCamera { // mirror original extension so reuse works
    var typeLabel: String {
        switch type { case .fixed: return "fixed"; case .mobile: return "mobile"; case .average: return "average" }
    }
}

#Preview { SpeedCameraRowView(camera: SpeedCamera(type: .fixed, distanceMeters: 120), distanceFormatter: { "\($0)m" }) }
