import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var locationManager: LocationManager
    @AppStorage("speedUnits") private var speedUnitsRaw: String = SpeedUnits.kmh.rawValue
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.6761, longitude: 12.5683), // Copenhagen default
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    ))
    @State private var isImageryStyle = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Map Header with modern design
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Location Map")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if locationManager.currentLocation != nil {
                        let units = SpeedUnits(rawValue: speedUnitsRaw) ?? .kmh
                        let value = Measurement(value: locationManager.currentSpeed, unit: UnitSpeed.metersPerSecond).converted(to: units.unitSpeed).value
                        Text("GPS Active • \(String(format: "%.1f", value)) \(units.displayName)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.green)
                    } else {
                        Text("GPS Inactive")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Map Style Toggle with modern design
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isImageryStyle.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isImageryStyle ? "map.fill" : "map")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(isImageryStyle ? "Satellite" : "Standard")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.9), Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Map with modern styling
            Map(position: $position) {
                // Current location marker with custom annotation
                if let location = locationManager.currentLocation {
                    Annotation("Current Location", coordinate: location.coordinate) {
                        ZStack {
                            // Outer ring
                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 24, height: 24)
                            
                            // Inner circle
                            Circle()
                                .fill(Color.red)
                                .frame(width: 16, height: 16)
                            
                            // Center dot
                            Circle()
                                .fill(Color.white)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                
                // Coordinate history path with gradient
                if locationManager.coordinateHistory.count > 1 {
                    MapPolyline(coordinates: locationManager.coordinateHistory)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        )
                }
            }
            .mapStyle(isImageryStyle ? .hybrid : .standard)
            .onChange(of: locationManager.currentLocation) { _, newLocation in
                if let location = newLocation {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        position = .region(MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    }
                }
            }
            
            // Enhanced Map Info Panel
            if let location = locationManager.currentLocation {
                VStack(spacing: 12) {
                    // GPS Status Bar
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            
                            Text("GPS Active")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "speedometer")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                            
                            let units = SpeedUnits(rawValue: speedUnitsRaw) ?? .kmh
                            let value = Measurement(value: locationManager.currentSpeed, unit: UnitSpeed.metersPerSecond).converted(to: units.unitSpeed).value
                            Text("\(String(format: "%.1f", value)) \(units.displayName)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Coordinates and Accuracy
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latitude")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.gray)
                            Text(String(format: "%.6f", location.coordinate.latitude))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Longitude")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.gray)
                            Text(String(format: "%.6f", location.coordinate.longitude))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Accuracy")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.gray)
                            Text("\(String(format: "%.1f", location.horizontalAccuracy))m")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.black)
    }
}

#Preview {
    MapView(locationManager: LocationManager())
        .preferredColorScheme(.dark)
}
