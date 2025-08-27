import SwiftUI

struct HomeSignsHarnessView: View {
    private let currentLimit: Int
    private let upcomingLimit: Int?
    @StateObject private var locationManager = LocationManager()

    init(currentLimit: Int, upcomingLimit: Int?) {
        self.currentLimit = currentLimit
        self.upcomingLimit = upcomingLimit
    }

    var body: some View {
        HomeView(locationManager: locationManager)
            .onAppear {
                locationManager.currentSpeedLimit = currentLimit
                locationManager.upcomingSpeedLimit = upcomingLimit
                UserDefaults.standard.set(false, forKey: "showSpeedometer")
                UserDefaults.standard.set(true, forKey: "showSpeedLimitSign")
            }
    }
}
