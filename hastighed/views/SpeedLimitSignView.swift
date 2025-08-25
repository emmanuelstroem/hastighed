import SwiftUI

struct SpeedLimitSignView: View {
    let speedLimit: Int?
    var size: CGFloat = 84

    var body: some View {
        Group {
            if let v = speedLimit {
                ZStack {
                    Circle()
                        .fill(Color.white)
                    Circle()
                        .stroke(Color.red, lineWidth: max(8, size * 0.14))
                    Text("\(v)")
                        .font(.system(size: size * 0.42, weight: .bold, design: .default))
                        .foregroundColor(.black)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                }
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Speed limit \(v) kilometers per hour"))
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SpeedLimitSignView(speedLimit: 50)
        SpeedLimitSignView(speedLimit: 110, size: 120)
    }
    .padding()
    .background(Color.black)
}
