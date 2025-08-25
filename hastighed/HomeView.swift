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
    @Namespace private var layoutNamespace
    
    private func isLandscape(_ geometry: GeometryProxy) -> Bool {
        geometry.size.width > geometry.size.height
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                adaptiveLayout(geometry: geometry)
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
        .animation(.easeInOut(duration: 0.35), value: horizontalSizeClass)
        .animation(.easeInOut(duration: 0.35), value: verticalSizeClass)
    }
    
    // MARK: - Debug Methods
    private func testMBTilesDatabase() {}
    
    // MARK: - Portrait Layout
    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Top: Speed Dial (takes half vertically)
            ZStack {
                if showSpeedometer {
                    SpeedDialView(
                        speedKmh: locationManager.currentSpeed * 3.6,
                        maxSpeedKmh: maxSpeedKmh,
                        size: min(geometry.size.width * 0.7, geometry.size.height * 0.45)
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom: Speed Limit sign (takes the other half)
            ZStack {
                if showSpeedLimitSign {
                    SpeedLimitSignView(
                        speedLimit: locationManager.currentSpeedLimit,
                        size: min(geometry.size.width * 0.5, geometry.size.height * 0.35)
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Debug overlay (live-updating since it observes locationManager)
        .overlay(alignment: .topLeading) {
            if showDebugOverlay {
                DebugInfoView(locationManager: locationManager, isCompact: true)
            }
        }
    }
    
    // MARK: - Landscape Layout (CarPlay Ultra style)
    @ViewBuilder
    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            // Main row equally split
            HStack(spacing: 0) {
                ZStack {
                    if showSpeedometer {
                        SpeedDialView(
                            speedKmh: locationManager.currentSpeed * 3.6,
                            maxSpeedKmh: maxSpeedKmh,
                            size: min(geometry.size.height * 0.7, geometry.size.width * 0.4)
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                ZStack {
                    if showSpeedLimitSign {
                        SpeedLimitSignView(
                            speedLimit: locationManager.currentSpeedLimit,
                            size: min(geometry.size.height * 0.5, geometry.size.width * 0.25)
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom strip: Street name only, takes space needed
            HStack {
                Spacer(minLength: 0)
                Text(locationManager.currentStreetName.isEmpty ? "" : locationManager.currentStreetName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
        }
        // Debug overlay for landscape as well
        .overlay(alignment: .topLeading) {
            if showDebugOverlay {
                DebugInfoView(locationManager: locationManager, isCompact: true)
            }
        }
    }

    // MARK: - Adaptive Layout with smooth orientation animation
    @ViewBuilder
    private func adaptiveLayout(geometry: GeometryProxy) -> some View {
        let landscape = isLandscape(geometry)
        let layout = landscape ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
        let totalWidth = geometry.size.width
        let totalHeight = geometry.size.height
        let primaryTotal = landscape ? totalWidth : totalHeight
        let primaryLarge = primaryTotal * 0.8
        let primarySmall = primaryTotal * 0.2

        // Containers along the primary axis (width in landscape, height in portrait)
        let dialContainerWidth = landscape ? primaryLarge : totalWidth
        let dialContainerHeight = landscape ? totalHeight : primaryLarge
        let signContainerWidth = landscape ? primarySmall : totalWidth
        let signContainerHeight = landscape ? totalHeight : primarySmall

        // Control rendered sizes inside containers
        let dialSize = min(dialContainerWidth, dialContainerHeight) * 0.92
        let signSize = min(signContainerWidth, signContainerHeight) * 0.8

        ZStack(alignment: .bottom) {
            layout {
                // Speed Dial
                ZStack {
                    if showSpeedometer {
                        SpeedDialView(
                            speedKmh: locationManager.currentSpeed * 3.6,
                            maxSpeedKmh: maxSpeedKmh,
                            size: dialSize
                        )
                        .matchedGeometryEffect(id: "speedDial", in: layoutNamespace)
                        .contentTransition(.identity)
                    }
                }
                .frame(width: dialContainerWidth, height: dialContainerHeight)

                // Speed Limit Sign
                ZStack {
                    if showSpeedLimitSign {
                        SpeedLimitSignView(
                            speedLimit: locationManager.currentSpeedLimit,
                            size: signSize
                        )
                        .matchedGeometryEffect(id: "speedLimit", in: layoutNamespace)
                        .contentTransition(.identity)
                    }
                }
                .frame(width: signContainerWidth, height: signContainerHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Street name overlay at bottom (landscape only)
            Text(locationManager.currentStreetName)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.2), in: Capsule())
                .opacity(landscape && !locationManager.currentStreetName.isEmpty ? 1 : 0)
                .animation(.easeInOut(duration: 0.25), value: landscape)
        }
        .overlay(alignment: .topLeading) {
            if showDebugOverlay {
                DebugInfoView(locationManager: locationManager, isCompact: true)
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
