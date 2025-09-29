//
//  ContentView.swift
//  hastighed
//
//  Created by Emmanuel on 18/09/2025.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var homeVM: HomeViewModel
    @StateObject private var settings = SettingsStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let locationService = LocationService()
        let phoneCountryService = PhoneCountryDetectionService(locationService: locationService)
        let connectivityService = ConnectivityService.shared
        let limitService = SpeedLimitService(phoneCountryService: phoneCountryService, connectivityService: connectivityService)
        let upcoming = MockUpcomingLimitProvider()
        let cameras = MockSpeedCameraProvider()
        let hazards = MockRoadHazardProvider()
        _homeVM = StateObject(wrappedValue: HomeViewModel(
            locationService: locationService,
            speedLimitService: limitService,
            upcomingProvider: upcoming,
            cameraProvider: cameras,
            hazardProvider: hazards
        ))
    }

    var body: some View {
        HomeView(viewModel: homeVM)
            .environmentObject(settings)
            .preferredColorScheme(.dark)
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    homeVM.requestPermissionIfNeeded()
                case .background, .inactive:
                    break
                @unknown default:
                    break
                }
            }
    }
}

#Preview {
    ContentView()
}
