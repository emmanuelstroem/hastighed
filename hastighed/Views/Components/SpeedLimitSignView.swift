import SwiftUI

struct SpeedLimitSignView: View {
    var limitValue: Double
    var unit: String = "km/h"
    var diameter: CGFloat = 150
    var ringColor: Color = .red
    var ringWidth: CGFloat = 14

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%.0f", limitValue))
                .font(.system(size: diameter * 0.42, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(Color.white))
                .overlay(Circle().stroke(ringColor, lineWidth: ringWidth))
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
