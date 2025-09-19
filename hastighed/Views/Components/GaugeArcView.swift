import SwiftUI

struct GaugeArcView: View {
    var lineWidth: CGFloat = 36
    var backgroundColor: Color = Color.white.opacity(0.07)
    var progressColor: Color = .teal
    var startTrim: CGFloat = 0.15
    var endTrim: CGFloat = 0.85
    var size: CGFloat = 320
    var progress: Double = 0 // 0...1

    private var clampProgress: Double { max(0, min(1, progress)) }

    var body: some View {
        ZStack {
            Circle()
                .trim(from: startTrim, to: endTrim)
                .stroke(backgroundColor, style: .init(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(90))
            if clampProgress > 0.001 {
                Circle()
                    .trim(from: startTrim, to: startTrim + (endTrim - startTrim) * clampProgress)
                    .stroke(progressColor.gradient, style: .init(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(90))
                    .animation(.easeInOut(duration: 0.35), value: clampProgress)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview { GaugeArcView(progress: 0.75) }
