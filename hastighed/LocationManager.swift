import Combine
import CoreLocation
import Foundation
import GeoToolbox
import MapKit
import SwiftUI
import UIKit
import os.log

@MainActor
class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let logger = Logger(
        subsystem: "com.eopio.hastighed",
        category: "LocationManager"
    )
    private var cancellables = Set<AnyCancellable>()

    // Use GeoPackage-based speed limit service (offline)
    let gpkgService = GeoPackageSpeedLimitService()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentStreetName: String = ""
    @Published var currentSpeed: Double = 0.0
    @Published var isLocationEnabled: Bool = false
    @Published var errorMessage: String?
    @Published var coordinateHistory: [CLLocationCoordinate2D] = []
    @Published var currentSpeedLimit: Int? = 0
    @Published var currentSpeedLimitRawValue: Int?
    @Published var currentSpeedLimitRawUnit: String?
    @Published var showPermissionAlert: Bool = false
    @AppStorage("speedUnits") private var speedUnitsRaw: String = SpeedUnits.kmh.rawValue

    // No smoothing: use Core Location's reported speed directly

    override init() {
        super.init()
        setupLocationManager()
        setupGeoPackageService()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .automotiveNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = false
    }

    private func setupGeoPackageService() {
        // Observe service for speed limit updates
        Publishers.CombineLatest3(
            gpkgService.$currentSpeedLimit,
            gpkgService.$currentSpeedLimitRawValue,
            gpkgService.$currentSpeedLimitRawUnit
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] speedLimitValue, rawVal, rawUnit in
            guard let self else { return }
            self.currentSpeedLimitRawValue = rawVal
            self.currentSpeedLimitRawUnit = rawUnit
            if let value = speedLimitValue {
                // Service already returns in selected unit; no conversion
                self.currentSpeedLimit = value
            } else {
                self.currentSpeedLimit = nil
            }
            // Persist raw tokens for UI consumption
            UserDefaults.standard.set(
                self.currentSpeedLimitRawValue,
                forKey: "currentSpeedLimitRawValue"
            )
            UserDefaults.standard.set(
                self.currentSpeedLimitRawUnit,
                forKey: "currentSpeedLimitRawUnit"
            )
            // Removed noisy print; rely on logger or UI bindings
        }
        .store(in: &cancellables)

        // Load any previously stored speed limit
        if let storedSpeedLimit = gpkgService.getStoredSpeedLimit() {
            currentSpeedLimit = storedSpeedLimit
        }
        let storedRaw = gpkgService.getStoredSpeedLimitRaw()
        currentSpeedLimitRawValue = storedRaw.0
        currentSpeedLimitRawUnit = storedRaw.1
    }

    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            showPermissionAlert = true
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }

    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func startLocationUpdates() {
        guard
            authorizationStatus == .authorizedWhenInUse
                || authorizationStatus == .authorizedAlways
        else {
            requestLocationPermission()
            return
        }

        locationManager.startUpdatingLocation()
        isLocationEnabled = true
        logger.info("Location updates started")

        // Immediately query speed limit if we have a location, or request one if we don't
        if let location = currentLocation {
            logger.info("Immediate speed limit query on app launch")
            gpkgService.querySpeedLimitImmediately(for: location)
        } else {
            // If no location yet, request one immediately
            logger.info(
                "Requesting immediate location for speed limit query on app launch"
            )
            locationManager.requestLocation()
        }

        // Note: Speed limit queries are handled by GeoPackage service and triggered on updates
    }

    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
        logger.info("Location updates stopped")
    }

    func refreshSpeedLimit() {
        if let location = currentLocation {
            gpkgService.querySpeedLimitImmediately(for: location)
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

                        let streetName = short ?? full ?? "Unknown street"
                        await MainActor.run {
                            if streetName != self.currentStreetName
                                && !streetName.isEmpty
                            {
                                self.currentStreetName = streetName
                                // Store in UserDefaults as specified in requirements
                                UserDefaults.standard.set(
                                    streetName,
                                    forKey: "currentStreetName"
                                )
                                self.logger.info(
                                    "Street name updated: \(streetName)"
                                )

                                // Update GeoPackage service with new street name (optional)
                                self.gpkgService.updateStreetName(streetName)
                                // Determine units by country (mph whitelist)
                                if let isoCode = item.placemark.isoCountryCode?.uppercased() {
                                    let mphCountries: Set<String> = [
                                        "US", "GB", "PR", "GU", "VI", "KY", "BS", "BZ"
                                    ]
                                    let selected: SpeedUnits = mphCountries.contains(isoCode) ? .mph : .kmh
                                    UserDefaults.standard.set(selected.rawValue, forKey: "speedUnits")
                                    self.logger.info("Units set by country \(isoCode): \(selected.displayName)")
                                }
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage =
                        "Failed to get street name: \(error.localizedDescription)"
                    self.logger.error(
                        "Geocoding failed: \(error.localizedDescription)"
                    )
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
            showPermissionAlert = true
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }

        currentLocation = location

        // Use Core Location's navigation speed directly (m/s). Negative means invalid; clamp at 0.
        // Docs: CLLocation.speed, CLLocationSpeed
        // https://developer.apple.com/documentation/corelocation/cllocation/speed
        // https://developer.apple.com/documentation/corelocation/cllocationspeed
        currentSpeed = max(location.speed, 0.0)
        // Quiet detailed per-update logging in production

        // Update service with current location
        gpkgService.updateCurrentLocation(location)

        // Query speed limit on each update to keep UI fresh
        gpkgService.querySpeedLimitImmediately(for: location)

        // Update street name when location changes (optional for gpkg)
        updateStreetName(for: location)

        // Note: Speed limit queries are handled by GeoPackage service
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        errorMessage = "Location error: \(error.localizedDescription)"
        isLocationEnabled = false
        logger.error("Location manager failed: \(error.localizedDescription)")
    }

}
