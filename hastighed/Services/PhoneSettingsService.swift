import Foundation
import CoreLocation
import Combine

/// Service for detecting the phone's current country/region from device settings
@MainActor
public class PhoneSettingsService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var currentCountryCode: String?
    @Published public private(set) var currentCountryName: String?
    @Published public private(set) var isDetecting = false
    @Published public private(set) var lastDetectionDate: Date?
    @Published public private(set) var detectionError: String?
    
    // MARK: - Private Properties
    
    private let locationService: LocationService
    private var cancellables = Set<AnyCancellable>()
    private let geocoder = CLGeocoder()
    
    // MARK: - Initialization
    
    init(locationService: LocationService) {
        self.locationService = locationService
        setupLocationObserver()
    }
    
    // MARK: - Public Methods
    
    /// Start detecting the current country from device location
    public func startDetection() {
        guard !isDetecting else { return }
        
        isDetecting = true
        detectionError = nil
        
        print("🌍 PhoneSettingsService: Starting country detection")
        print("🌍 PhoneSettingsService: Location service authorization status: \(locationService.authorizationStatus.rawValue)")
        
        // If we have a recent location, use it immediately
        if let location = locationService.latestLocation {
            print("🌍 PhoneSettingsService: Using existing location: \(location.coordinate)")
            detectCountry(from: location)
        } else {
            print("🌍 PhoneSettingsService: No existing location, waiting for location update...")
            // Wait for location update
            locationService.coordinatePublisher
                .compactMap { $0 }
                .first()
                .sink { [weak self] coordinate in
                    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    print("🌍 PhoneSettingsService: Received new location: \(location.coordinate)")
                    self?.detectCountry(from: location)
                }
                .store(in: &cancellables)
        }
    }
    
    /// Get the recommended dataset for the current country
    public func getRecommendedDataset() -> DatasetListing? {
        guard let countryCode = currentCountryCode else { return nil }
        
        // Map country codes to dataset identifiers
        let countryMapping: [String: String] = [
            "DK": "denmark",
            "SE": "sweden", 
            "LI": "liechtenstein"
        ]
        
        if let datasetId = countryMapping[countryCode] {
            return DatasetListing.allDatasets.first { $0.datasetIdentifier == datasetId }
        }
        
        return nil
    }
    
    /// Get all available datasets excluding the current country
    public func getOtherDatasets() -> [DatasetListing] {
        guard let currentDataset = getRecommendedDataset() else {
            return DatasetListing.allDatasets
        }
        
        return DatasetListing.allDatasets.filter { $0.datasetIdentifier != currentDataset.datasetIdentifier }
    }
    
    // MARK: - Private Methods
    
    private func setupLocationObserver() {
        locationService.coordinatePublisher
            .sink { [weak self] coordinate in
                guard let coordinate = coordinate else { return }
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                self?.detectCountry(from: location)
            }
            .store(in: &cancellables)
    }
    
    private func detectCountry(from location: CLLocation) {
        print("🌍 PhoneSettingsService: Detecting country from location: \(location.coordinate)")
        print("🌍 PhoneSettingsService: Location accuracy: \(location.horizontalAccuracy) meters")
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isDetecting = false
                
                if let error = error {
                    print("❌ PhoneSettingsService: Geocoding failed: \(error)")
                    print("❌ PhoneSettingsService: Error details: \(error.localizedDescription)")
                    self?.detectionError = error.localizedDescription
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    print("⚠️ PhoneSettingsService: No placemarks found")
                    self?.detectionError = "No location information found"
                    return
                }
                
                guard let countryCode = placemark.isoCountryCode else {
                    print("⚠️ PhoneSettingsService: No country code found in placemark")
                    print("⚠️ PhoneSettingsService: Placemark details: \(placemark)")
                    self?.detectionError = "Unable to determine country code"
                    return
                }
                
                let countryName = placemark.country ?? "Unknown"
                print("✅ PhoneSettingsService: Successfully detected country!")
                print("✅ PhoneSettingsService: Country Code: \(countryCode)")
                print("✅ PhoneSettingsService: Country Name: \(countryName)")
                print("✅ PhoneSettingsService: Full placemark: \(placemark)")
                
                self?.currentCountryCode = countryCode
                self?.currentCountryName = countryName
                self?.lastDetectionDate = Date()
                self?.detectionError = nil
            }
        }
    }
}
