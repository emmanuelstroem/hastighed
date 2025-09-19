import SwiftUI

struct RoadHazardRowView: View {
    let hazard: RoadHazard
    let distanceFormatter: (Double) -> String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(hazard.typeLabel)
                .font(.headline)
            Spacer()
            Text(distanceFormatter(hazard.distanceMeters))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

private extension RoadHazard { // replicate label logic
    var typeLabel: String {
        switch type { case .schoolZone: return "school"; case .sharpTurn: return "turn"; case .roadworks: return "works" }
    }
}

#Preview { RoadHazardRowView(hazard: RoadHazard(type: .schoolZone, distanceMeters: 90), distanceFormatter: { "\($0)m" }) }
