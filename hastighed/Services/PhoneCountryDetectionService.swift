import Foundation
import CoreLocation
import MapKit
import Combine
import MapKit // Added for MKReverseGeocodingRequest

/// Service for detecting the phone's current country/region from device settings
@MainActor
public class PhoneCountryDetectionService: ObservableObject {
    
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
        
        
        // If we have a recent location, use it immediately
        if let location = locationService.latestLocation {
            detectCountry(from: location)
        } else {
            // Wait for location update
            locationService.coordinatePublisher
                .compactMap { $0 }
                .first()
                .sink { [weak self] coordinate in
                    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
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
        if #available(iOS 26.0, *) {
            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.isDetecting = false }
                guard let request = MKReverseGeocodingRequest(location: location) else {
                    self.detectionError = "Unable to create reverse geocoding request"
                    return
                }
                do {
                    let mapItems = try await request.mapItems
                    guard let mapItem = mapItems.first else {
                        self.detectionError = "Unable to determine country"
                        return
                    }
                    let placemark = mapItem.placemark
                    guard let countryCode = placemark.isoCountryCode else {
                        self.detectionError = "Unable to determine country"
                        return
                    }
                    self.currentCountryCode = countryCode
                    self.currentCountryName = placemark.country
                    self.lastDetectionDate = Date()
                    self.detectionError = nil
                } catch {
                    self.detectionError = error.localizedDescription
                }
            }
        } else {
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isDetecting = false
                    if let error = error {
                        self.detectionError = error.localizedDescription
                        return
                    }
                    guard let placemark = placemarks?.first,
                          let countryCode = placemark.isoCountryCode else {
                        self.detectionError = "Unable to determine country"
                        return
                    }
                    self.currentCountryCode = countryCode
                    self.currentCountryName = placemark.country
                    self.lastDetectionDate = Date()
                    self.detectionError = nil
                }
            }
        }
    }
}
