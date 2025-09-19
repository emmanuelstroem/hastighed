import SwiftUI

struct SpeedLimitSignView: View {
    var limitValue: Double
    var unit: String = "km/h"
    var diameter: CGFloat = 150
    var ringColor: Color = .red
    var ringWidth: CGFloat = 14

    var body: some View {
        let numberFontSize = diameter * 0.42
        let clampedRing = min(max(8, diameter * 0.09), 20)
        VStack(spacing: 4) {
            Text(String(format: "%.0f", limitValue))
                .font(.system(size: numberFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(Color.white))
                .overlay(Circle().stroke(ringColor, lineWidth: clampedRing))
                .accessibilityHidden(true)
//            Text(unit)
//                .font(.footnote)
//                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Speed limit")
        .accessibilityValue(String(format: "%.0f %@", limitValue, unit))
    }
}

#Preview { SpeedLimitSignView(limitValue: 50) }
