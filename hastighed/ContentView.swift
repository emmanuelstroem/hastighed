import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        Group {
            if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                HomeView(locationManager: locationManager)
            } else {
                PermissionView(locationManager: locationManager)
            }
        }
        .onAppear {
            // Check if we already have a stored street name
            if let storedStreetName = UserDefaults.standard.string(forKey: "currentStreetName") {
                locationManager.currentStreetName = storedStreetName
            }
        }
    }
}

#Preview {
    ContentView()
}