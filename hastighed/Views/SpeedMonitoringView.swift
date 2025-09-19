import SwiftUI

struct SpeedMonitoringView: View {
    @ObservedObject var viewModel: SpeedMonitoringViewModel

    private func color(for status: LimitStatus) -> Color {
        switch status {
        case .below: return Color.green.opacity(0.85)
        case .near: return Color.orange.opacity(0.9)
        case .over: return Color.red.opacity(0.9)
        }
    }

    private func deltaText(for status: LimitStatus) -> String {
        switch status {
        case .below(let d): return "−" + String(format: "%.0f", d.value)
        case .near(let d): return String(format: "±%.0f", d.value)
        case .over(let d): return "+" + String(format: "%.0f", d.value)
        }
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            VStack(spacing: 8) {
                Text(formattedSpeed)
                    .font(.system(size: 86, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.3)
                    .contentTransition(.numericText())
                Text("km/h")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 4) {
                Text("Limit")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(limitValue)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(deltaText(for: viewModel.status))
                    .font(.subheadline.monospacedDigit())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(color(for: viewModel.status).gradient)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: color(for: viewModel.status).opacity(0.25), radius: 20, y: 8)
            VStack(spacing: 12) {
                Slider(value: $viewModel.tolerance, in: 1...10, step: 1) {
                    Text("Tolerance")
                }
                Text("Tolerance: ±\(Int(viewModel.tolerance)) km/h")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            Spacer()
            Text("Always follow posted signs. Experimental limits.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.35), value: viewModel.status)
    }

    private var formattedSpeed: String {
        guard let reading = viewModel.speedReading else { return "--" }
        return String(format: "%.0f", reading.speed.value)
    }

    private var limitValue: String {
        String(format: "%.0f", viewModel.speedLimit.value.value)
    }
}

#Preview {
    SpeedMonitoringView(viewModel: .preview())
        .preferredColorScheme(.dark)
}
