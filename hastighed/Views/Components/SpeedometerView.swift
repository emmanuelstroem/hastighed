import SwiftUI

struct SpeedometerView: View {
    var speedValue: Double
    var unit: String = "km/h"
    /// Diameter used to derive proportional typography.
    var diameter: CGFloat = 140

    var body: some View {
        let numberFontSize = diameter * 0.44
        VStack(spacing: 8) {
            Text(String(format: "%.0f", speedValue))
                .font(.system(size: numberFontSize, weight: .medium, design: .rounded))
                .contentTransition(.numericText())
                .minimumScaleFactor(0.4)
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
