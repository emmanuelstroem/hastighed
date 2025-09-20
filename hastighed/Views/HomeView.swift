import SwiftUI
import _LocationEssentials
import CoreLocation

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.horizontalSizeClass) private var hSize
    @EnvironmentObject private var settings: SettingsStore
    @State private var showingSettings = false

    private func accuracyBadge(_ acc: CLLocationAccuracy?) -> some View {
        guard let acc else { return AnyView(EmptyView()) }
        let quality: String
        let color: Color
        switch acc {
        case ..<15: quality = "good"; color = .green
        case 15..<35: quality = "ok"; color = .orange
        default: quality = "poor"; color = .red
        }
        return AnyView(Text("±" + String(format: "%.0f", acc) + " m • " + quality)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule()))
    }

    private var speedText: String { String(format: "%.0f", viewModel.speedReading?.speed.value ?? 0) }
    private var limitText: String { String(format: "%.0f", viewModel.speedLimit.value.value) }

    private func sectionCard<T: Identifiable, Content: View>(title: String, items: [T], @ViewBuilder content: @escaping (T) -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text(title).font(.caption.smallCaps()).foregroundStyle(.secondary); Spacer() }
            ForEach(items) { item in
                content(item)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func upcomingLimitRow(_ change: UpcomingSpeedLimitChange) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.turn.up.right.diamond")
            Text(String(format: "%.0f", change.newLimit.value.value))
                .font(.headline.monospacedDigit())
            Spacer()
            Text(distanceString(change.distanceMeters))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func cameraRow(_ camera: SpeedCamera) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "camera.fill")
            Text(camera.typeLabel)
                .font(.headline)
            Spacer()
            Text(distanceString(camera.distanceMeters))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func hazardRow(_ hazard: RoadHazard) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(hazard.typeLabel)
                .font(.headline)
            Spacer()
            Text(distanceString(hazard.distanceMeters))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func distanceString(_ meters: Double) -> String {
        if meters < 1000 { return String(format: "%.0fm", meters) }
        return String(format: "%.1fkm", meters / 1000)
    }

    var body: some View {
        GeometryReader { proxy in
            let guide = LayoutGuide(containerSize: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
            let isLandscape = proxy.size.width >= proxy.size.height
            ZStack {
                if isLandscape {
                    landscapeLayout(guide: guide, proxy: proxy)
                        .transition(.opacity)
                } else {
                    portraitLayout(guide: guide, proxy: proxy)
                        .transition(.opacity)
                }
                if viewModel.shouldShowPermissionOverlay {
                    permissionOverlay
                        .transition(.opacity)
                }
                if settings.isDebugOverlayEnabled {
                    VStack { HStack { DebugOverlayView(snapshot: viewModel.debugSnapshot); Spacer() }; Spacer() }
                        .allowsHitTesting(false)
                        .transition(.opacity)
                        .accessibilityIdentifier("debugOverlay")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .background(Color.black.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
                .animation(.easeInOut(duration: 0.2), value: isLandscape)
                .onAppear { viewModel.requestPermissionIfNeeded() }
        }
    }

    private func gauge(diameter: CGFloat) -> some View {
        let speedKmh = viewModel.speedReading?.speed.value ?? 0
        let displaySpeed = settings.displaySpeed(from: speedKmh)
        let limitKmh = viewModel.speedLimit.value.value
        return ZStack {
            GaugeArcView(diameter: diameter, speedValue: speedKmh, speedLimit: limitKmh)
            SpeedometerView(speedValue: displaySpeed, unit: settings.speedUnitLabel, diameter: diameter)
        }
        .accessibilityIdentifier("gauge")
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func speedLimitSign(diameter: CGFloat) -> some View {
        let limitKmh = viewModel.speedLimit.value.value
        let displayLimit = settings.displayLimit(from: limitKmh)
        return SpeedLimitSignView(limitValue: displayLimit, unit: settings.speedUnitLabel, diameter: diameter)
            .padding(.bottom, 8)
            .accessibilityIdentifier("speedLimitSign")
    }

    private func portraitLayout(guide: LayoutGuide, proxy: GeometryProxy) -> some View {
        VStack(spacing: max(16, guide.spacing * 1.5)) {
            HStack { Spacer(); settingsButton }
            // Stack gauge and sign vertically in portrait
            VStack(spacing: max(12, guide.spacing)) {
                if settings.showGauge {
                    gauge(diameter: guide.gaugeDiameterPortrait(maxWidth: proxy.size.width))
                }
                if settings.showSpeedLimit {
                    speedLimitSign(diameter: guide.signDiameter)
                }
            }
            if hasContextData {
                contextChips
            }
            VStack(spacing: 6) {
                accuracyBadge(viewModel.locationAccuracy)
                Text("Experimental data – always follow posted signs.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func landscapeLayout(guide: LayoutGuide, proxy: GeometryProxy) -> some View {
        VStack(spacing: max(20, guide.spacing * 1.2)) {
            HStack(alignment: .top, spacing: max(24, guide.spacing * 1.6)) {
                // Place gauge and sign side-by-side in landscape
                gauge(diameter: guide.gaugeDiameterLandscape(maxHeight: proxy.size.height))
                VStack(alignment: .trailing, spacing: max(12, guide.spacing)) {
                    HStack { Spacer(); settingsButton }
                    speedLimitSign(diameter: guide.signDiameter)
                    Spacer(minLength: 0)
                }
            }
            // Secondary information below
            VStack(alignment: .leading, spacing: max(20, guide.spacing * 1.4)) {
                if settings.showSpeedLimit && !viewModel.upcomingLimitChanges.isEmpty { sectionCard(title: "Upcoming Limits", items: viewModel.upcomingLimitChanges, content: upcomingLimitRow) }
                if settings.showSpeedCameras && !viewModel.speedCameras.isEmpty { sectionCard(title: "Speed Cameras", items: viewModel.speedCameras) { SpeedCameraRowView(camera: $0, distanceFormatter: distanceString) } }
                if settings.showHazards && !viewModel.roadHazards.isEmpty { sectionCard(title: "Hazards", items: viewModel.roadHazards) { RoadHazardRowView(hazard: $0, distanceFormatter: distanceString) } }
                HStack { Spacer(); accuracyBadge(viewModel.locationAccuracy) }
            }
        }
    }

    private var hasContextData: Bool {
        !viewModel.upcomingLimitChanges.isEmpty || !viewModel.speedCameras.isEmpty || !viewModel.roadHazards.isEmpty
    }

    private var contextChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.upcomingLimitChanges) { change in
                    chip(label: String(format: "→ %.0f", change.newLimit.value.value), distance: change.distanceMeters, color: .blue)
                }
                ForEach(viewModel.speedCameras) { cam in
                    chip(label: cam.typeLabel.capitalized, distance: cam.distanceMeters, color: .red)
                }
                ForEach(viewModel.roadHazards) { hazard in
                    chip(label: hazard.typeLabel, distance: hazard.distanceMeters, color: .orange)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func chip(label: String, distance: Double, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color.opacity(0.85)).frame(width: 10, height: 10)
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
            Text(distanceString(distance))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.07))
        .clipShape(Capsule())
    }

    private var settingsButton: some View {
        Button(action: { showingSettings = true }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18))
                .foregroundStyle(.white)
                .padding(14)
                .background(Circle().fill(Color.white.opacity(0.1)))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("settingsButton")
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: settings)
                .preferredColorScheme(.dark)
        }
    }

    private var permissionOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash")
                .font(.system(size: 36, weight: .bold))
            Text("Location Permission Needed")
                .font(.headline)
            Text("To show your driving speed and nearby limits, enable Location for this app.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button("Open Settings") { viewModel.openSettings() }
                    .buttonStyle(.borderedProminent)
                Button("Not now") { /* dismiss remains overlay until granted; no-op */ }
                    .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(maxWidth: 420)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(radius: 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5).ignoresSafeArea())
    }
}

private extension SpeedCamera {
    var typeLabel: String {
        switch type { case .fixed: return "fixed"; case .mobile: return "mobile"; case .average: return "average" }
    }
}

private extension RoadHazard {
    var typeLabel: String {
        switch type { case .schoolZone: return "school"; case .sharpTurn: return "turn"; case .roadworks: return "works" }
    }
}

#Preview {
    HomeView(viewModel: .preview())
        .environmentObject(SettingsStore())
        .preferredColorScheme(.dark)
}
