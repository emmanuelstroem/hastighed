import SwiftUI

struct GaugeArcView: View {
    var diameter: CGFloat = 320
    var lineWidth: CGFloat = 26
    var backgroundColor: Color = Color.white.opacity(0.07)
    var startTrim: CGFloat = 0.15
    var endTrim: CGFloat = 0.85
    // New inputs for dynamic color & progress
    var speedValue: Double = 0
    var speedLimit: Double = 0

    private var buffer: Double { max(0, speedLimit * 0.05) }
    private var thresholdMax: Double { max(1, speedLimit + buffer) }
    private var computedProgress: Double {
        let p = speedValue / thresholdMax
        return max(0, min(1, p))
    }
    private var computedColor: Color {
        if speedValue <= speedLimit { return .teal }
        if speedValue <= speedLimit + buffer { return .orange }
        return .red
    }

    var body: some View {
        let clampedLineWidth = min(lineWidth, max(4, diameter * 0.11))
        ZStack {
            Circle()
                .trim(from: startTrim, to: endTrim)
                .stroke(backgroundColor, style: .init(lineWidth: clampedLineWidth, lineCap: .round))
                .rotationEffect(.degrees(90))
            if computedProgress > 0.001 {
                Circle()
                    .trim(from: startTrim, to: startTrim + (endTrim - startTrim) * computedProgress)
                    .stroke(computedColor.gradient, style: .init(lineWidth: clampedLineWidth, lineCap: .round))
                    .rotationEffect(.degrees(90))
                    .animation(.easeInOut(duration: 0.35), value: computedProgress)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }
}

#Preview { GaugeArcView(speedValue: 80, speedLimit: 90) }
