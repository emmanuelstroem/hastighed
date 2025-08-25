import SwiftUI

struct SpeedDialView: View {
    let speedKmh: Double
    let maxSpeedKmh: Double
    var size: CGFloat = 200
    var batteryLevel: Double = 0.0 // Default battery level (0.0 to 1.0)
    
    // Visual tuning
    private var speedArcThickness: CGFloat { size * 0.05 }
    private var energyArcThickness: CGFloat { size * 0.018 } // thinner energy bar like reference
    private var arcSeparationInset: CGFloat { size * 0.005 } // more separation so bars never appear to touch
    private var energyPaddingDegrees: Double { 8 } // angular padding so ends never meet speed ends
    // Draw energy clockwise centered on bottom gap (225°..315°)
    private var energyStartDegrees: Double { 315 - energyPaddingDegrees }
    private var energySweepDegrees: Double { max(0, 90 - (2 * energyPaddingDegrees)) } // fit within remaining arc
    
    // Convert km/h to mph for display
    private var speedMph: Double {
        speedKmh * 0.621371
    }
    
    private var maxSpeedMph: Double {
        maxSpeedKmh * 0.621371
    }
    
    private var progress: Double {
        guard maxSpeedMph > 0 else { return 0 }
        return min(max(speedMph / maxSpeedMph, 0), 1)
    }
    
    // Estimated range calculation
    private var estimatedRangeMiles: Int {
        max(200 - Int(speedMph * 2), 50) // Simple calculation for demo
    }
    
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
                        .animation(.easeInOut(duration: 0.45), value: progress)
                    
                    // Energy progress inside bottom gap, smaller sweep and thinner
                    ArcSegment(startAngleDegrees: energyStartDegrees, sweepDegrees: energySweepDegrees, progress: max(min(batteryLevel, 1), 0), inset: arcSeparationInset, clockwise: true)
                        .stroke(
                            (batteryLevel < 0.25)
                            ? LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]), startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(gradient: Gradient(colors: [Color.cyan, Color.blue.opacity(0.9)]), startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: energyArcThickness, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                        .shadow(color: (batteryLevel < 0.25 ? Color.orange : Color.cyan).opacity(0.35), radius: 4)
                        .animation(.easeInOut(duration: 0.45), value: batteryLevel)
                }
            }
            .rotationEffect(.degrees(180))
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                
                // Speed display
                VStack(spacing: size * 0.02) {
                    Text("\(Int(speedMph.rounded()))")
                        .font(.system(size: size * 0.35, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    
                    Text("km/h")
                        .font(.system(size: size * 0.08, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current speed \(Int(speedMph.rounded())) miles per hour. Estimated range \(estimatedRangeMiles) miles. Battery level \(Int((batteryLevel * 100).rounded())) percent")
        .accessibilityValue("Speed is \(Int((progress * 100).rounded())) percent of maximum")
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
                speedKmh: 96.56, 
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
