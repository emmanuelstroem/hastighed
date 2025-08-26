import SwiftUI

struct HomeView: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @AppStorage("showDebugOverlay") private var showDebugOverlay: Bool = true
    @AppStorage("showSpeedometer") private var showSpeedometer: Bool = true
    @AppStorage("showSpeedLimitSign") private var showSpeedLimitSign: Bool =
        true
    @AppStorage("showStreetName") private var showStreetName: Bool = true
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
            SettingsSheet(
                showDebugOverlay: $showDebugOverlay,
                showSpeedometer: $showSpeedometer,
                showSpeedLimitSign: $showSpeedLimitSign,
                showStreetName: $showStreetName
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .animation(.easeInOut(duration: 0.35), value: horizontalSizeClass)
        .animation(.easeInOut(duration: 0.35), value: verticalSizeClass)
        .alert("Location Permission Required", isPresented: $locationManager.showPermissionAlert) {
            Button("Open Settings") {
                locationManager.openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This app needs access to your location to function properly.")
        }
    }

    // (Removed unused debug method)

    // MARK: - Portrait Layout
    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Top: Speed Dial (takes half vertically)
            ZStack {
                if showSpeedometer {
                    SpeedDialView(
                        speedKmh: Measurement(value: locationManager.currentSpeed, unit: UnitSpeed.metersPerSecond).converted(to: UnitSpeed.kilometersPerHour).value,
                        maxSpeedKmh: maxSpeedKmh,
                        size: min(
                            geometry.size.width * 0.7,
                            geometry.size.height * 0.45
                        ),
                        speedLimitKmh: Double(locationManager.currentSpeedLimit ?? 0)
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom: Speed Limit sign (takes the other half)
            ZStack {
                if showSpeedLimitSign {
                    SpeedLimitSignView(
                        speedLimit: locationManager.currentSpeedLimit,
                        size: min(
                            geometry.size.width * 0.5,
                            geometry.size.height * 0.35
                        )
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
                            speedKmh: Measurement(value: locationManager.currentSpeed, unit: UnitSpeed.metersPerSecond).converted(to: UnitSpeed.kilometersPerHour).value,
                            maxSpeedKmh: maxSpeedKmh,
                            size: min(
                                geometry.size.height * 0.7,
                                geometry.size.width * 0.4
                            ),
                            speedLimitKmh: Double(locationManager.currentSpeedLimit ?? 0)
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                ZStack {
                    if showSpeedLimitSign {
                        SpeedLimitSignView(
                            speedLimit: locationManager.currentSpeedLimit,
                            size: min(
                                geometry.size.height * 0.5,
                                geometry.size.width * 0.25
                            )
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom strip: Street name only, takes space needed
            if showStreetName {
                HStack {
                    Spacer(minLength: 0)
                    Text(
                        locationManager.currentStreetName.isEmpty
                            ? "" : locationManager.currentStreetName
                    )
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
            }
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
        let layout =
            landscape
            ? AnyLayout(HStackLayout(spacing: 0))
            : AnyLayout(VStackLayout(spacing: 0))
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
                if showSpeedometer && showSpeedLimitSign {
                    // Both visible: place around the same center using offsets for a pivot illusion
                    ZStack {
                        let dialOffset =
                            landscape
                            ? CGSize(width: -(primarySmall / 2), height: 0)
                            : CGSize(width: 0, height: -(primarySmall / 2))
                        let signOffset =
                            landscape
                            ? CGSize(width: (primaryLarge / 2), height: 0)
                            : CGSize(width: 0, height: (primaryLarge / 2))

                        // Dial (80%)
                        ZStack {
                            SpeedDialView(
                                speedKmh: Measurement(value: locationManager.currentSpeed, unit: UnitSpeed.metersPerSecond).converted(to: UnitSpeed.kilometersPerHour).value,
                                maxSpeedKmh: maxSpeedKmh,
                                size: dialSize
                            )
                            .matchedGeometryEffect(
                                id: "speedDial",
                                in: layoutNamespace,
                                properties: .position,
                                anchor: .center
                            )
                            .contentTransition(.identity)
                        }
                        .frame(
                            width: dialContainerWidth,
                            height: dialContainerHeight
                        )
                        .offset(dialOffset)
                        .animation(nil, value: dialContainerWidth)
                        .animation(nil, value: dialContainerHeight)

                        // Speed limit (20%)
                        ZStack {
                            SpeedLimitSignView(
                                speedLimit: locationManager.currentSpeedLimit,
                                size: signSize
                            )
                            .matchedGeometryEffect(
                                id: "speedLimit",
                                in: layoutNamespace,
                                properties: .position,
                                anchor: .center
                            )
                            .contentTransition(.identity)
                        }
                        .frame(
                            width: signContainerWidth,
                            height: signContainerHeight
                        )
                        .offset(signOffset)
                        .animation(nil, value: signContainerWidth)
                        .animation(nil, value: signContainerHeight)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if showSpeedometer {
                    // Only dial visible: center it
                    ZStack {
                        SpeedDialView(
                            speedKmh: locationManager.currentSpeed * 3.6,
                            maxSpeedKmh: maxSpeedKmh,
                            size: min(totalWidth, totalHeight) * 0.92,
                            speedLimitKmh: Double(locationManager.currentSpeedLimit ?? 0)
                        )
                        .matchedGeometryEffect(
                            id: "speedDial",
                            in: layoutNamespace,
                            properties: .position,
                            anchor: .center
                        )
                        .contentTransition(.identity)
                    }
                    .frame(width: totalWidth, height: totalHeight)
                    .animation(nil, value: landscape)
                } else if showSpeedLimitSign {
                    // Only speed limit visible: center it
                    ZStack {
                        SpeedLimitSignView(
                            speedLimit: locationManager.currentSpeedLimit,
                            size: min(totalWidth, totalHeight) * 0.6
                        )
                        .matchedGeometryEffect(
                            id: "speedLimit",
                            in: layoutNamespace,
                            properties: .position,
                            anchor: .center
                        )
                        .contentTransition(.identity)
                    }
                    .frame(width: totalWidth, height: totalHeight)
                    .animation(nil, value: landscape)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Street name overlay at bottom (landscape only)
            if showStreetName {
                Text(locationManager.currentStreetName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.2), in: Capsule())
                    .opacity(
                        landscape && !locationManager.currentStreetName.isEmpty
                            ? 1 : 0
                    )
                    .animation(.easeInOut(duration: 0.25), value: landscape)
            }
        }
        .overlay(alignment: .topLeading) {
            if showDebugOverlay {
                DebugInfoView(locationManager: locationManager, isCompact: true)
            }
        }
    }
}

// Preview trimmed to avoid deprecated modifiers warnings
#Preview("Portrait") {
    HomeView(locationManager: LocationManager())
}
