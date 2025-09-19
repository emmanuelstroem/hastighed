import SwiftUI

struct SpeedometerView: View {
    var speedValue: Double
    var unit: String = "km/h"
    var size: CGFloat = 140

    var body: some View {
        VStack(spacing: 8) {
            Text(String(format: "%.0f", speedValue))
                .font(.system(size: size, weight: .medium, design: .rounded))
                .contentTransition(.numericText())
                .minimumScaleFactor(0.3)
            Text(unit)
                .foregroundStyle(.secondary)
                .font(.headline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current speed")
        .accessibilityValue(String(format: "%.0f %@", speedValue, unit))
    }
}

#Preview { SpeedometerView(speedValue: 72) }
