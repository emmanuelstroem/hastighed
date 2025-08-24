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
    private let osmService = OSMService()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentStreetName: String = ""
    @Published var currentSpeed: Double = 0.0
    @Published var isLocationEnabled: Bool = false
    @Published var errorMessage: String?
    @Published var coordinateHistory: [CLLocationCoordinate2D] = []
    @Published var currentSpeedLimit: Int?
    
    override init() {
        super.init()
        setupLocationManager()
        setupOSMService()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1.0 // Update every 1 meter
        locationManager.allowsBackgroundLocationUpdates = false
    }
    
    private func setupOSMService() {
        // Observe OSM service for speed limit updates
        osmService.$currentSpeedLimit
            .receive(on: DispatchQueue.main)
            .sink { [weak self] speedLimit in
                self?.currentSpeedLimit = speedLimit
            }
            .store(in: &cancellables)
        
        // Load any previously stored speed limit
        if let storedSpeedLimit = osmService.getStoredSpeedLimit() {
            currentSpeedLimit = storedSpeedLimit
        }
        
        // Listen for speed limit check requests from OSMService
        NotificationCenter.default.addObserver(
            forName: .speedLimitCheckRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSpeedLimitCheckRequest()
            }
        }
    }
    
    private func handleSpeedLimitCheckRequest() {
        if let location = currentLocation {
            logger.info("Speed limit check requested by OSMService")
            osmService.querySpeedLimit(for: location)
        }
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
        
        // Immediately query speed limit if we have a location, or request one if we don't
        if let location = currentLocation {
            logger.info("Immediate speed limit query on app launch")
            osmService.querySpeedLimitImmediately(for: location)
        } else {
            // If no location yet, request one immediately
            logger.info("Requesting immediate location for speed limit query on app launch")
            locationManager.requestLocation()
        }
        
        // Note: Speed limit queries are now handled by OSMService based on street changes and 10-second intervals
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
        logger.info("Location updates stopped")
    }
    
    func refreshSpeedLimit() {
        if let location = currentLocation {
            osmService.querySpeedLimit(for: location)
        }
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
                        
                        let streetName = short ?? full ?? "Unkn own street"
                        await MainActor.run {
                            if streetName != self.currentStreetName && !streetName.isEmpty {
                                self.currentStreetName = streetName
                                // Store in UserDefaults as specified in requirements
                                UserDefaults.standard.set(streetName, forKey: "currentStreetName")
                                self.logger.info("Street name updated: \(streetName)")
                                
                                // Update OSMService with new street name and trigger speed limit check
                                self.osmService.updateStreetName(streetName)
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
        
        // Update OSMService with current location
        osmService.updateCurrentLocation(location)
        
        // If this is the first location update (app launch), query speed limit immediately
        if currentSpeedLimit == nil {
            logger.info("First location update on app launch - querying speed limit immediately")
            osmService.querySpeedLimitImmediately(for: location)
        }
        
        // Update street name when location changes (this will trigger speed limit check if street changed)
        updateStreetName(for: location)
        
        // Note: Speed limit queries are now handled by OSMService based on street changes and 10-second intervals
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
        isLocationEnabled = false
        logger.error("Location manager failed: \(error.localizedDescription)")
    }
    

}
