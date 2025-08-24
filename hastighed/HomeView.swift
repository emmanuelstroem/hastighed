import SwiftUI

struct HomeView: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var isLandscape: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .compact
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if isLandscape {
                        landscapeLayout(geometry: geometry)
                    } else {
                        portraitLayout(geometry: geometry)
                    }
                }
            }
        }
        .onAppear {
            locationManager.startLocationUpdates()
        }
        .onDisappear {
            locationManager.stopLocationUpdates()
        }
        .onTapGesture(count: 2) {
            // Double tap to refresh speed limit (for testing)
            locationManager.refreshSpeedLimit()
        }
    }
    
    // MARK: - Portrait Layout
    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Speed Display (Large number in center)
            VStack(spacing: 20) {
                Text("\(Int(locationManager.currentSpeed * 3.6))") // Convert m/s to km/h
                    .font(.system(size: 120, weight: .thin, design: .default))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Text("km/h")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Street Name and Speed Limit
            VStack(spacing: 20) {
                // Street Name
                VStack(spacing: 8) {
                    Text("Current Street")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(locationManager.currentStreetName.isEmpty ? "Acquiring location..." : locationManager.currentStreetName)
                        .font(.title3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 20)
                }
                
                // Speed Limit
                VStack(spacing: 8) {
                    Text("Speed Limit")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let speedLimit = locationManager.currentSpeedLimit {
                        Text("\(speedLimit) km/h")
                            .font(.title)
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    } else {
                        Text("Detecting...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Landscape Layout (CarPlay Ultra style)
    @ViewBuilder
    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 40) {
            // Left side - Speedometer dial
            VStack {
                Spacer()
                
                ZStack {
                    // Outer circle
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 200, height: 200)
                    
                    // Speed arc
                    Circle()
                        .trim(from: 0, to: min(locationManager.currentSpeed * 3.6 / 200, 1.0)) // 200 km/h max
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: locationManager.currentSpeed)
                    
                    // Center speed number
                    VStack(spacing: 4) {
                        Text("\(Int(locationManager.currentSpeed * 3.6))")
                            .font(.system(size: 48, weight: .bold, design: .default))
                            .foregroundColor(.white)
                        
                        Text("km/h")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .frame(width: geometry.size.width * 0.4)
            
            // Right side - Street info and status
            VStack(alignment: .leading, spacing: 30) {
                Spacer()
                
                // GPS Status
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: locationManager.isLocationEnabled ? "location.fill" : "location.slash")
                            .foregroundColor(locationManager.isLocationEnabled ? .green : .red)
                        Text("GPS Status")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Text(locationManager.isLocationEnabled ? "Active" : "Inactive")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Street Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Location")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(locationManager.currentStreetName.isEmpty ? "Acquiring location..." : locationManager.currentStreetName)
                        .font(.title2)
                        .foregroundColor(.white)
                        .lineLimit(3)
                }
                
                // Speed Limit Display
                VStack(alignment: .leading, spacing: 8) {
                    Text("Speed Limit")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let speedLimit = locationManager.currentSpeedLimit {
                        Text("\(speedLimit) km/h")
                            .font(.title2)
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    } else {
                        Text("Detecting...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .frame(width: geometry.size.width * 0.6)
            .padding(.trailing, 40)
        }
    }
}

#Preview {
    Group {
        HomeView(locationManager: LocationManager())
            .previewDevice("iPhone 15 Pro")
            .previewDisplayName("Portrait")
        
        HomeView(locationManager: LocationManager())
            .previewDevice("iPhone 15 Pro")
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDisplayName("Landscape")
    }
}