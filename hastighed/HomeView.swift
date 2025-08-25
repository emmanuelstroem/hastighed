import SwiftUI

struct HomeView: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @AppStorage("showDebugOverlay") private var showDebugOverlay: Bool = true
    @AppStorage("showSpeedometer") private var showSpeedometer: Bool = true
    @AppStorage("showSpeedLimitSign") private var showSpeedLimitSign: Bool = true
    @State private var showingSettings = false
    
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
        .onTapGesture(count: 3) {
            // Triple tap: quick toggle debug overlay
            showDebugOverlay.toggle()
        }
        // Settings gear overlay
        .overlay(alignment: .topTrailing) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding([.top, .trailing], 12)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet(showDebugOverlay: $showDebugOverlay,
                          showSpeedometer: $showSpeedometer,
                          showSpeedLimitSign: $showSpeedLimitSign)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Debug Methods
    private func testMBTilesDatabase() {}
    
    // MARK: - Portrait Layout
    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Speed Display (Large number in center) with optional speed limit sign subtly overlaid on the right
            ZStack(alignment: .center) {
                if showSpeedometer {
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
                    .transition(.opacity)
                }

                // Overlay: speed limit sign to the right side
                if showSpeedLimitSign {
                    HStack {
                        Spacer()
                        // Scale sign size with screen width to avoid stealing focus
                        SpeedLimitSignView(speedLimit: locationManager.currentSpeedLimit, size: min(84, geometry.size.width * 0.18))
                            .padding(.trailing, 24)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.opacity)
                }
            }
            
            Spacer()
            
            // Street Name and (optional) Speed Limit status
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
                
                // Only show status text when we don't yet have a speed limit; the sign above provides the value
                if locationManager.currentSpeedLimit == nil {
                    VStack(spacing: 8) {
                        Text("Speed Limit")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Detecting...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        // Debug overlay (live-updating since it observes locationManager)
        .overlay(alignment: .topLeading) {
            if showDebugOverlay {
                DebugInfoView(locationManager: locationManager)
            }
        }
    }
    
    // MARK: - Landscape Layout (CarPlay Ultra style)
    @ViewBuilder
    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 40) {
            // Left side - Speedometer dial with optional speed limit sign subtly overlaid on the right
            VStack {
                Spacer()
                
                ZStack {
                    // Outer circle
                    if showSpeedometer {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 200, height: 200)
                            .transition(.opacity)
                    }
                    
                    // Speed arc
                    if showSpeedometer {
                        Circle()
                            .trim(from: 0, to: min(locationManager.currentSpeed * 3.6 / 200, 1.0)) // 200 km/h max
                            .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: locationManager.currentSpeed)
                            .transition(.opacity)
                    }
                    
                    // Center speed number
                    if showSpeedometer {
                        VStack(spacing: 4) {
                            Text("\(Int(locationManager.currentSpeed * 3.6))")
                                .font(.system(size: 48, weight: .bold, design: .default))
                                .foregroundColor(.white)
                            
                            Text("km/h")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .transition(.opacity)
                    }
            // Overlay sign on the right side of the dial (smaller, to keep focus on speed)
                    if showSpeedLimitSign {
                        VStack {
                            HStack {
                                Spacer()
                                SpeedLimitSignView(speedLimit: locationManager.currentSpeedLimit, size: min(72, geometry.size.width * 0.06))
                            }
                            Spacer()
                        }
                        .padding(.trailing, 8)
                        .transition(.opacity)
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
                
                // Only show status text if we don't have a limit yet (avoid competing with the sign on the dial)
                if locationManager.currentSpeedLimit == nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Speed Limit")
                            .font(.headline)
                            .foregroundColor(.white)
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
        // Debug overlay for landscape as well
        .overlay(alignment: .topLeading) {
            if showDebugOverlay {
                DebugInfoView(locationManager: locationManager)
            }
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