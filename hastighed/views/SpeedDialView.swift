import SwiftUI

struct SpeedDialView: View {
    let speedKmh: Double
    let maxSpeedKmh: Double
    var size: CGFloat = 200
    var batteryLevel: Double = 0.0 // Ignored for now
    var speedLimitKmh: Double? = nil
    
    // Visual tuning
    private var speedArcThickness: CGFloat { size * 0.05 }
    private var energyArcThickness: CGFloat { 0 }
    private var arcSeparationInset: CGFloat { 0 }
    private var energyPaddingDegrees: Double { 0 }
    private var energyStartDegrees: Double { 315 }
    private var energySweepDegrees: Double { 0 }
    
    @AppStorage("speedUnits") private var speedUnitsRaw: String = SpeedUnits.kmh.rawValue
    private var units: SpeedUnits { SpeedUnits(rawValue: speedUnitsRaw) ?? .kmh }
    
    private var displaySpeed: Double {
        units.convertFromKmh(speedKmh)
    }
    
    private var displayMaxSpeed: Double {
        units.convertFromKmh(maxSpeedKmh)
    }
    
    private var progress: Double {
        guard displayMaxSpeed > 0 else { return 0 }
        return min(max(displaySpeed / displayMaxSpeed, 0), 1)
    }
    
    private var displayLimit: Double? {
        guard let limit = speedLimitKmh, limit > 0 else { return nil }
        return units.convertFromKmh(limit)
    }
    
    private var displayLimitThreshold: Double? {
        guard let limit = displayLimit else { return nil }
        return limit * 1.05
    }
    
    // No range/battery calculations needed currently
    
    var body: some View {
        ZStack {
            // Arcs container (no rotation; angles chosen so speed is top, energy sits within bottom gap)
            ZStack {
                // Background tracks
                Group {
                    // Speed track: 270° (leaves a 90° gap at bottom from 225°..315°)
                    ArcSegment(startAngleDegrees: 315, sweepDegrees: 270, progress: 1.0, inset: 0, clockwise: false)
                        .stroke(
                            Color.white.opacity(0.10),
                            style: StrokeStyle(lineWidth: speedArcThickness, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                    
                    // Energy track: a subset of the remaining gap, centered at bottom and inset
                    ArcSegment(startAngleDegrees: energyStartDegrees, sweepDegrees: energySweepDegrees, progress: 1.0, inset: arcSeparationInset, clockwise: true)
                        .stroke(
                            Color.white.opacity(0.10),
                            style: StrokeStyle(lineWidth: energyArcThickness, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                }
                
                // Live progress arcs
                Group {
                    // Speed progress on its own ring (270°)
                    if let _ = displayLimit, let _ = displayLimitThreshold {
                        let severity = SpeedDialView.determineSeverity(speedKmh: speedKmh, limitKmh: speedLimitKmh, units: units)
                        switch severity {
                        case .within:
                            ArcSegment(startAngleDegrees: 315, sweepDegrees: 270, progress: progress, inset: 0, clockwise: false)
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [
                                            Color.cyan.opacity(0.7),
                                            Color.cyan,
                                            Color.teal,
                                            Color.cyan
                                        ]),
                                        center: .center,
                                        startAngle: .degrees(315),
                                        endAngle: .degrees(585)
                                    ),
                                    style: StrokeStyle(lineWidth: speedArcThickness, lineCap: .round)
                                )
                                .frame(width: size, height: size)
                                .shadow(color: .cyan.opacity(0.30), radius: 6)
                        case .buffer:
                            ArcSegment(startAngleDegrees: 315, sweepDegrees: 270, progress: progress, inset: 0, clockwise: false)
                                .stroke(
                                    Color.orange,
                                    style: StrokeStyle(lineWidth: speedArcThickness, lineCap: .round)
                                )
                                .frame(width: size, height: size)
                                .shadow(color: .orange.opacity(0.30), radius: 6)
                        case .over:
                            ArcSegment(startAngleDegrees: 315, sweepDegrees: 270, progress: progress, inset: 0, clockwise: false)
                                .stroke(
                                    Color.red,
                                    style: StrokeStyle(lineWidth: speedArcThickness, lineCap: .round)
                                )
                                .frame(width: size, height: size)
                                .shadow(color: .red.opacity(0.30), radius: 6)
                        }
                    } else {
                        ArcSegment(startAngleDegrees: 315, sweepDegrees: 270, progress: progress, inset: 0, clockwise: false)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        Color.cyan.opacity(0.7),
                                        Color.cyan,
                                        Color.teal,
                                        Color.cyan
                                    ]),
                                    center: .center,
                                    startAngle: .degrees(315),
                                    endAngle: .degrees(585)
                                ),
                                style: StrokeStyle(lineWidth: speedArcThickness, lineCap: .round)
                            )
                            .frame(width: size, height: size)
                            .shadow(color: .cyan.opacity(0.30), radius: 6)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: displaySpeed)
            }
            .rotationEffect(.degrees(180))
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                
                // Speed display
                VStack(spacing: size * 0.02) {
                    Text("\(Int(displaySpeed.rounded()))")
                        .accessibilityIdentifier("speedValue")
                        .font(.system(size: size * 0.35, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    
                    Text(units.displayName)
                        .font(.system(size: size * 0.08, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current speed \(Int(displaySpeed.rounded())) \(units.displayName)")
        .accessibilityValue("Speed is \(Int((progress * 100).rounded())) percent of maximum")
        .accessibilityIdentifier("speedDial")
    }
}

// MARK: - Generic Arc Segment Shape
/// Draws an arc segment from a given start angle with a given sweep, scaled by progress.
/// Angles are in degrees, 0° is at the positive X-axis (right), increasing counterclockwise.
private struct ArcSegment: Shape {
    let startAngleDegrees: Double
    let sweepDegrees: Double
    let progress: Double
    let inset: CGFloat
    let clockwise: Bool
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = (min(rect.width, rect.height) / 2) - inset
        let clamped = max(0, min(progress, 1))
        let start = Angle(degrees: startAngleDegrees)
        let end: Angle
        if clockwise {
            end = Angle(degrees: startAngleDegrees - (sweepDegrees * clamped))
        } else {
            end = Angle(degrees: startAngleDegrees + (sweepDegrees * clamped))
        }
        p.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: clockwise)
        return p
    }
}

// MARK: - Testing helpers
extension SpeedDialView {
    enum SpeedSeverity { case within, buffer, over }
    static func determineSeverity(speedKmh: Double, limitKmh: Double?, units: SpeedUnits) -> SpeedSeverity {
        guard let limitKmh, limitKmh > 0 else { return .within }
        let displaySpeed = units.convertFromKmh(speedKmh)
        let displayLimit = units.convertFromKmh(limitKmh)
        let threshold = displayLimit * 1.05
        if displaySpeed <= displayLimit { return .within }
        if displaySpeed <= threshold { return .buffer }
        return .over
    }
}

#Preview {
    ZStack {
        // Match the app's dark background
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color(red: 0.05, green: 0.15, blue: 0.2)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack(spacing: 30) {
            // High speed, good battery
            SpeedDialView(
                speedKmh: 92,
                maxSpeedKmh: 201,
                size: 280, 
                batteryLevel: 0.8
            ) // 60 mph in km/h, 80% battery
            
            // Medium speed, low battery
            SpeedDialView(
                speedKmh: 48.28, 
                maxSpeedKmh: 201, 
                size: 200, 
                batteryLevel: 0.2
            ) // 30 mph in km/h, 20% battery
        }
        .padding()
    }
}
