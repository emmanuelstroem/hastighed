import SwiftUI

struct HomeView: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @AppStorage("showDebugOverlay") private var showDebugOverlay: Bool = true
    @AppStorage("showSpeedometer") private var showSpeedometer: Bool = true
    @AppStorage("showSpeedLimitSign") private var showSpeedLimitSign: Bool = true
    @AppStorage("maxSpeedKmh") private var maxSpeedKmh: Double = 201
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
            VStack(alignment: .center, spacing: 24) {
                if showSpeedometer {
                    SpeedDialView(
                        speedKmh: locationManager.currentSpeed * 3.6,
                        maxSpeedKmh: maxSpeedKmh,
                        size: min(300, geometry.size.width * 0.55)
                    )
                    .transition(.opacity)
                }
                if showSpeedLimitSign {
                    SpeedLimitSignView(
                        speedLimit: locationManager.currentSpeedLimit,
                        size: min(150, geometry.size.width * 0.35)
                    )
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
        HStack(spacing: 28) {
            // Landscape: side-by-side — speed (left) and speed-limit sign (right)
            HStack(spacing: 40) {
                // Speed dial/number (hero)
                ZStack {
                    if showSpeedometer {
                        SpeedDialView(
                            speedKmh: locationManager.currentSpeed * 3.6,
                            maxSpeedKmh: maxSpeedKmh,
                            size: min(300, geometry.size.height * 0.5)
                        )
                    }
                }
                .frame(maxWidth: .infinity)

                // Speed-limit sign
                if showSpeedLimitSign {
                    SpeedLimitSignView(speedLimit: locationManager.currentSpeedLimit ?? 0,
                                        size: min(150, geometry.size.height * 0.35))
                        .frame(maxWidth: .infinity)
                } else {
                    Spacer().frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
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
    }
}
