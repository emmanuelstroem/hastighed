import Foundation
import CoreLocation
import MapKit
import SwiftUI
import Combine
import os.log
import GeoToolbox

@MainActor
class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let logger = Logger(subsystem: "com.eopio.hastighed", category: "LocationManager")
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentStreetName: String = ""
    @Published var currentSpeed: Double = 0.0
    @Published var isLocationEnabled: Bool = false
    @Published var errorMessage: String?
    @Published var coordinateHistory: [CLLocationCoordinate2D] = []
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1.0 // Update every 1 meter
        locationManager.allowsBackgroundLocationUpdates = false
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access is required for this app to function properly."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
        isLocationEnabled = true
        logger.info("Location updates started")
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
        logger.info("Location updates stopped")
    }
    
    private func updateStreetName(for location: CLLocation) {
        // Use modern MapKit reverse geocoding for iOS 26
        
        Task {
            do {
                // Get street name
                if let request = MKReverseGeocodingRequest(location: location) {
                    let mapItems = try await request.mapItems
                    if let item = mapItems.first {
                        // Access address via new MKAddress properties
                        let full = item.address?.fullAddress
                        let short = item.address?.shortAddress
                        
                        let streetName = short ?? full ?? "Unknown street"
                        await MainActor.run {
                            if streetName != self.currentStreetName && !streetName.isEmpty {
                                self.currentStreetName = streetName
                                // Store in UserDefaults as specified in requirements
                                UserDefaults.standard.set(streetName, forKey: "currentStreetName")
                                self.logger.info("Street name updated: \(streetName)")
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to get street name: \(error.localizedDescription)"
                    self.logger.error("Geocoding failed: \(error.localizedDescription)")
                }
            }
        }
            }
    }
    
    // MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            isLocationEnabled = false
            errorMessage = "Location access denied. Please enable in Settings."
            logger.warning("Location access denied")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        currentSpeed = location.speed >= 0 ? location.speed : 0.0
        
        // Update street name when location changes
        updateStreetName(for: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
        isLocationEnabled = false
        logger.error("Location manager failed: \(error.localizedDescription)")
    }
}
