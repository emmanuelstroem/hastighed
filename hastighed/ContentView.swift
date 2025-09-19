//
//  ContentView.swift
//  hastighed
//
//  Created by Emmanuel on 18/09/2025.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var viewModel: SpeedMonitoringViewModel

    init() {
        let locationService = LocationService()
        let limitService = SpeedLimitService()
        _viewModel = StateObject(wrappedValue: SpeedMonitoringViewModel(locationService: locationService, speedLimitService: limitService))
    }

    var body: some View {
        SpeedMonitoringView(viewModel: viewModel)
            .preferredColorScheme(.dark) // MVP: dark style for contrast
    }
}

#Preview {
    ContentView()
}
