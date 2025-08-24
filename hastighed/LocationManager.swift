import Foundation
import CoreLocation
import MapKit
import SwiftUI
import Combine
import os.log

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
        // Use CLGeocoder for reliable reverse geocoding (still the recommended approach)
        // This is NOT deprecated for reverse geocoding - only the old completion handler style is deprecated
        Task {
            do {
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                
                if let placemark = placemarks.first {
                    let streetName = extractStreetNameFromPlacemark(placemark)
                    
                    await MainActor.run {
                        if streetName != self.currentStreetName && !streetName.isEmpty {
                            self.currentStreetName = streetName
                            // Store in UserDefaults as specified in requirements
                            UserDefaults.standard.set(streetName, forKey: "currentStreetName")
                            self.logger.info("Street name updated: \(streetName)")
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
    
    private func extractStreetNameFromPlacemark(_ placemark: CLPlacemark) -> String {
        // Get street name directly from the placemark properties
        var addressComponents: [String] = []
        
        // Add street number if available
        if let streetNumber = placemark.subThoroughfare, !streetNumber.isEmpty {
            addressComponents.append(streetNumber)
        }
        
        // Add street name if available
        if let streetName = placemark.thoroughfare, !streetName.isEmpty {
            addressComponents.append(streetName)
            
            // Return the combined street address
            if !addressComponents.isEmpty {
                return addressComponents.joined(separator: " ")
            }
        }
        
        // If no street name, try to construct from coordinates
        if let location = placemark.location {
            return String(format: "Location %.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
        }
        
        return "Unknown Street"
    }
    
    private func logLocationUpdate(_ location: CLLocation) {
        let coordinates = location.coordinate
        let accuracy = location.horizontalAccuracy
        let speed = location.speed
        let timestamp = location.timestamp
        
        logger.info("Location Update - Lat: \(String(format: "%.6f", coordinates.latitude)), Lon: \(String(format: "%.6f", coordinates.longitude)), Accuracy: \(String(format: "%.1f", accuracy))m, Speed: \(String(format: "%.1f", speed))m/s, Time: \(timestamp)")
        
        // Add to coordinate history (keep last 100 points)
        coordinateHistory.append(coordinates)
        if coordinateHistory.count > 100 {
            coordinateHistory.removeFirst()
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
        
        // Log the location update
        logLocationUpdate(location)
        
        // Update street name when location changes
        updateStreetName(for: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
        isLocationEnabled = false
        logger.error("Location manager failed: \(error.localizedDescription)")
    }
}
