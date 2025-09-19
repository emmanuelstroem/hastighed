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

    init() {
        let locationService = LocationService()
        let limitService = SpeedLimitService()
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
    }
}

#Preview {
    ContentView()
}
