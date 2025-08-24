import SwiftUI
import CoreLocation

struct HomeView: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var selectedTab = 0
    
    private var isLandscape: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .compact
    }
    
    var body: some View {
        if isLandscape {
            // Landscape: Use the original instrument cluster layout
            landscapeLayout
        } else {
            // Portrait: Use tab-based interface
            TabView(selection: $selectedTab) {
                // Speedometer Tab
                VStack(spacing: 0) {
                    // Header with GPS status
                    VStack(spacing: 12) {
                        Text("Speedometer")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if let _ = locationManager.currentLocation {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                                
                                Text("GPS Active")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.2))
                            .clipShape(Capsule())
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "location.slash")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                
                                Text("GPS Inactive")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.2))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Main Speed Display
                    if let location = locationManager.currentLocation {
                        VStack(spacing: 32) {
                            // Speed Circle with modern design
                            ZStack {
                                // Background circle with subtle gradient
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 280, height: 280)
                                
                                // Red outline ring
                                Circle()
                                    .stroke(Color.red, lineWidth: 6)
                                    .frame(width: 280, height: 280)
                                
                                // Speed text
                                VStack(spacing: 8) {
                                    Text("\(Int(locationManager.currentSpeed * 3.6))")
                                        .font(.system(size: 72, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .contentTransition(.numericText())
                                    
                                    Text("km/h")
                                        .font(.system(size: 20, weight: .medium, design: .rounded))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            // Coordinates display
                            VStack(spacing: 8) {
                                Text("Coordinates")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.gray)
                                
                                Text(String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude))
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }
                    } else {
                        // GPS Waiting State
                        VStack(spacing: 32) {
                            Image(systemName: "location.circle")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                            
                            Text("Waiting for GPS...")
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .foregroundColor(.gray)
                            
                            Text("Please ensure location services are enabled")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    
                    Spacer()
                    
                    // Street Name Display
                    VStack(spacing: 8) {
                        Text("Current Street")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                        
                        Text(locationManager.currentStreetName.isEmpty ? "Unknown Street" : locationManager.currentStreetName)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                }
                .tabItem {
                    Image(systemName: "speedometer")
                    Text("Speed")
                }
                .tag(0)
                
                // Map Tab
                MapView(locationManager: locationManager)
                    .tabItem {
                        Image(systemName: "map")
                        Text("Map")
                    }
                    .tag(1)
            }
            .background(Color.black)
            .accentColor(.white)
            .preferredColorScheme(.dark)
        }
    }
    
    private var landscapeLayout: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    colors: [Color.black, Color.black.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                HStack(spacing: 0) {
                    // Left side - CarPlay Ultra inspired speedometer
                    VStack(spacing: 0) {
                        // Header with GPS status
                        HStack {
                            Image(systemName: "speedometer")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Speed")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // GPS Status indicator
                            if let _ = locationManager.currentLocation {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                    
                                    Text("GPS")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .clipShape(Capsule())
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.slash")
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange)
                                    
                                    Text("GPS")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        // Speedometer Dial with CarPlay Ultra design
                        ZStack {
                            // Background circles for depth
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 280, height: 280)
                            
                            Circle()
                                .fill(Color.white.opacity(0.03))
                                .frame(width: 260, height: 260)
                            
                            // Main speed ring
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 16)
                                .frame(width: 240, height: 240)
                            
                            // Speed indicator ring with smooth animation
                            Circle()
                                .trim(from: 0, to: min(locationManager.currentSpeed / 50.0, 1.0))
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.red, Color.orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                )
                                .frame(width: 240, height: 240)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.0), value: locationManager.currentSpeed)
                            
                            // Center speed display
                            VStack(spacing: 8) {
                                if let _ = locationManager.currentLocation {
                                    Text("\(Int(locationManager.currentSpeed * 3.6))")
                                        .font(.system(size: 64, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .contentTransition(.numericText())
                                    
                                    Text("km/h")
                                        .font(.system(size: 20, weight: .medium, design: .rounded))
                                        .foregroundColor(.gray)
                                } else {
                                    Text("--")
                                        .font(.system(size: 64, weight: .bold, design: .rounded))
                                        .foregroundColor(.gray)
                                    
                                    Text("km/h")
                                        .font(.system(size: 20, weight: .medium, design: .rounded))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Street name display
                        VStack(spacing: 8) {
                            Text("Current Location")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.gray)
                            
                            Text(locationManager.currentStreetName.isEmpty ? "Unknown Street" : locationManager.currentStreetName)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 20)
                        }
                    }
                    .frame(width: geometry.size.width * 0.4)
                    .background(
                        LinearGradient(
                            colors: [Color.black, Color.black.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Right side - Map
                    MapView(locationManager: locationManager)
                        .frame(width: geometry.size.width * 0.6)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.trailing, 20)
                }
            }
        }
    }
}

#Preview {
    HomeView(locationManager: LocationManager())
        .previewDevice("iPhone 15 Pro")
        .previewDisplayName("Portrait")
}

#Preview {
    HomeView(locationManager: LocationManager())
        .previewDevice("iPhone 15 Pro")
        .previewInterfaceOrientation(.landscapeLeft)
        .previewDisplayName("Landscape")
}
