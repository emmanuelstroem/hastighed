import SwiftUI

struct SpeedLimitSignView: View {
    let speedLimit: Int?
    var size: CGFloat = 84
    var dimmed: Bool = false
    @AppStorage("speedUnits") private var speedUnitsRaw: String = SpeedUnits.kmh
        .rawValue
    private var units: SpeedUnits {
        SpeedUnits(rawValue: speedUnitsRaw) ?? .kmh
    }
    @State private var rawValueStored: Int? =
        UserDefaults.standard.object(forKey: "currentSpeedLimitRawValue")
        as? Int
    @State private var rawUnitStored: String? =
        UserDefaults.standard.object(forKey: "currentSpeedLimitRawUnit")
        as? String

    private var convertedLimit: Int? { speedLimit }

    private var displayUnitLabel: String {
        if let u = rawUnitStored, !u.isEmpty { return u }
        return units.displayName
    }

    var body: some View {
        Group {
            if let v = convertedLimit {
                ZStack {
                    Circle()
                        .fill(dimmed ? Color.gray.opacity(0.35) : Color.white)
                    Circle()
                        .stroke(dimmed ? Color.gray : Color.red, lineWidth: max(8, size * 0.05))
                    Text("\(v)")
                        .font(
                            .system(
                                size: size * 0.42,
                                weight: .bold,
                                design: .default
                            )
                        )
                        .foregroundColor(dimmed ? Color.black.opacity(0.6) : .black)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.horizontal, 6)

                    // Raw unit overlay below number
                    VStack {
                        Spacer(minLength: 0)
                        Text(displayUnitLabel)
                            .font(
                                .system(
                                    size: size * 0.10,
                                    weight: .semibold,
                                    design: .rounded
                                )
                            )
                            .foregroundColor(dimmed ? Color.black.opacity(0.55) : .black.opacity(0.8))
                            .padding(.bottom, size * 0.08)
                    }
                }
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    Text("Speed limit \(v) \(displayUnitLabel)")
                )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SpeedLimitSignView(speedLimit: 50)
        SpeedLimitSignView(speedLimit: 60)
        SpeedLimitSignView(speedLimit: 110, size: 120)
        SpeedLimitSignView(speedLimit: 130, size: 120)
        SpeedLimitSignView(speedLimit: 80, size: 120, dimmed: true)
    }
    .padding()
    .background(Color.black)
}
