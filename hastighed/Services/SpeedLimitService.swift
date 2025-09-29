import Foundation
import CoreLocation
import Combine

protocol SpeedLimitProviding {
    func currentSpeedLimit(for location: CLLocation?) -> SpeedLimit
    func currentSpeedLimitPublisher(for location: CLLocation?) -> AnyPublisher<SpeedLimit, Never>
    func updateSpeedLimit(for location: CLLocation?) async
    var currentSpeedLimit: SpeedLimit { get }
}

/// Speed limit service with GPKG integration and fallback implementation
@MainActor
final class SpeedLimitService: SpeedLimitProviding, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var currentSpeedLimit: SpeedLimit = SpeedLimit(kmh: 50, source: .ruleFallback, confidence: 0.3)
    @Published public private(set) var currentStreetName: String?
    @Published public private(set) var currentHazard: String?
    @Published public private(set) var lastQueryTime: Date?
    @Published public private(set) var isOfflineMode: Bool = false
    
    // MARK: - Private Properties
    
    private let phoneCountryService: PhoneCountryDetectionService
    private let connectivityService: ConnectivityService
    private let gpkgQueryService: GpkgQueryService
    private let downloadService: DownloadService
    private var cancellables = Set<AnyCancellable>()
    private var currentCountryCode: String?
    private var gpkgFilePath: String?
    private var lastConnectivityStatus: ConnectivityStatus?
    private var lastStreetName: String?
    
    // MARK: - Initialization
    
    init(phoneCountryService: PhoneCountryDetectionService, connectivityService: ConnectivityService) {
        self.phoneCountryService = phoneCountryService
        self.connectivityService = connectivityService
        self.gpkgQueryService = GpkgQueryService()
        self.downloadService = DownloadService()
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Get current speed limit for location (synchronous)
    func currentSpeedLimit(for location: CLLocation?) -> SpeedLimit {
        return currentSpeedLimit
    }
    
    /// Get current speed limit publisher for location
    func currentSpeedLimitPublisher(for location: CLLocation?) -> AnyPublisher<SpeedLimit, Never> {
        return $currentSpeedLimit.eraseToAnyPublisher()
    }
    
    /// Update speed limit for location (asynchronous)
    func updateSpeedLimit(for location: CLLocation?) async {
        guard let location = location else {
            await updateWithFallbackSpeedLimit()
            return
        }
        
        guard currentCountryCode != nil else {
            await updateWithFallbackSpeedLimit()
            return
        }
        
        if isOfflineMode {
            await updateWithGpkgQuery(for: location)
        } else {
            if connectivityService.isInternetUsable() {
                await updateWithOnlineQuery(for: location)
            } else {
                await updateWithGpkgQuery(for: location)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Country observer
        phoneCountryService.$currentCountryCode
            .sink { [weak self] countryCode in
                Task { @MainActor in
                    await self?.handleCountryChange(to: countryCode)
                }
            }
            .store(in: &cancellables)
        
        // Connectivity observer
        _ = connectivityService.onStatusChange { [weak self] status in
            Task { @MainActor in
                await self?.handleConnectivityChange(status: status)
            }
        }
    }
    
    private func handleCountryChange(to countryCode: String?) async {
        let previousCountry = currentCountryCode
        if previousCountry != countryCode {
            logCountryChange(from: previousCountry, to: countryCode)
        }
        currentCountryCode = countryCode
        guard countryCode != nil else { return }
        await setupGpkgDatabase()
    }
    
    private func updateWithFallbackSpeedLimit() async {
        let fallbackSpeed = getFallbackSpeedLimit(for: currentCountryCode ?? "XX")
        await MainActor.run {
            let previousSpeed = Int(self.currentSpeedLimit.value.converted(to: .kilometersPerHour).value.rounded())
            logMaxspeedChange(from: previousSpeed, to: fallbackSpeed)
            logStreetNameChange(from: lastStreetName, to: nil)
            self.currentSpeedLimit = SpeedLimit(kmh: Double(fallbackSpeed), source: .ruleFallback, confidence: 0.5)
            self.currentStreetName = nil
            self.currentHazard = nil
            self.lastStreetName = nil
        }
    }
    
    private func getFallbackSpeedLimit(for countryCode: String) -> Int {
        switch countryCode.uppercased() {
        case "DK": return 50 // Denmark
        case "SE": return 50 // Sweden
        case "NO": return 50 // Norway
        case "DE": return 50 // Germany
        case "FR": return 50 // France
        case "GB", "UK": return 48 // UK (30 mph ≈ 48 km/h)
        default: return 50
        }
    }
    
    // MARK: - GPKG Integration
    
    private func updateWithGpkgQuery(for location: CLLocation) async {
        if !gpkgQueryService.isOpen {
            await setupGpkgDatabase()
        }
        
        guard gpkgQueryService.isOpen else {
            await updateWithFallbackSpeedLimit()
            return
        }
        
        do {
            let result = try await gpkgQueryService.querySpeedLimit(at: location.coordinate)
            if let result = result, let speedLimitString = result.primarySpeedLimit {
                let speedLimit = parseSpeedLimit(from: speedLimitString)
                let source: SpeedLimit.Source = result.source == .roadSegment ? .offlineMap : .offlineTraffic
                
                await MainActor.run {
                    let previousSpeed = Int(self.currentSpeedLimit.value.converted(to: .kilometersPerHour).value.rounded())
                    logMaxspeedChange(from: previousSpeed, to: speedLimit)
                    logStreetNameChange(from: lastStreetName, to: result.streetName)
                    self.currentSpeedLimit = SpeedLimit(
                        kmh: Double(speedLimit),
                        source: source,
                        confidence: result.confidence
                    )
                    self.currentStreetName = result.streetName
                    self.lastStreetName = result.streetName
                    self.currentHazard = result.hazardInfo
                    self.lastQueryTime = Date()
                }
            } else {
                await updateWithFallbackSpeedLimit()
            }
        } catch {
            await updateWithFallbackSpeedLimit()
        }
    }
    
    private func updateWithOnlineQuery(for location: CLLocation) async {
        // TODO: Implement online speed limit query
        // For now, fallback to GPKG or country default
        await updateWithGpkgQuery(for: location)
    }
    
    private func handleConnectivityChange(status: ConnectivityStatus) async {
        if lastConnectivityStatus?.networkType != status.networkType {
            logConnectivityTypeChange(from: lastConnectivityStatus?.networkType, to: status.networkType)
        }
        if !status.usable && !isOfflineMode {
            isOfflineMode = true
            await setupGpkgDatabase()
        } else if status.usable && isOfflineMode {
            isOfflineMode = false
        }
        lastConnectivityStatus = status
    }
    
    private func setupGpkgDatabase() async {
        guard let countryCode = currentCountryCode else { return }
        
        let datasetIdentifier = getDatasetIdentifier(for: countryCode)
        guard downloadService.localFileExists(for: datasetIdentifier) else {
            return
        }
        
        guard let gpkgPath = downloadService.localFilePath(for: datasetIdentifier) else {
            return
        }
        
        do {
            try gpkgQueryService.openDatabase(at: gpkgPath)
            gpkgFilePath = gpkgPath
        } catch {
        }
    }
    
    private func getDatasetIdentifier(for countryCode: String) -> String {
        switch countryCode.uppercased() {
        case "DK": return "denmark"
        case "SE": return "sweden"
        case "LI": return "liechtenstein"
        case "NO": return "norway"
        case "DE": return "germany"
        case "FR": return "france"
        case "GB", "UK": return "uk"
        default: return "denmark" // Default to Denmark for unsupported countries
        }
    }
    
    private func getGpkgFileName(for countryCode: String) -> String {
        let datasetIdentifier = getDatasetIdentifier(for: countryCode)
        return "\(datasetIdentifier).gpkg"
    }
    
    private func parseSpeedLimit(from string: String) -> Int {
        // Extract numeric value from speed limit string
        let numbers = string.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        
        if let firstNumber = numbers.first {
            return firstNumber
        }
        
        // Fallback to country default
        return getFallbackSpeedLimit(for: currentCountryCode ?? "XX")
    }
}

// MARK: - Logging Helpers

private func logConnectivityTypeChange(from previous: NetworkType?, to current: NetworkType) {
    guard previous != current else { return }
    print("ℹ️ ConnectivityType: \(describeNetworkType(previous)) --> \(describeNetworkType(current))")
}

private func logCountryChange(from previous: String?, to current: String?) {
    guard previous != current else { return }
    print("ℹ️ Country: \(formatCountry(previous)) --> \(formatCountry(current))")
}

private func logStreetNameChange(from previous: String?, to current: String?) {
    guard previous != current else { return }
    print("ℹ️ Street: \(formatOptional(previous)) --> \(formatOptional(current))")
}

private func logMaxspeedChange(from previous: Int?, to current: Int?) {
    guard previous != current else { return }
    print("ℹ️ Speed Limit: \(describeSpeed(previous)) --> \(describeSpeed(current))")
}

private func describeNetworkType(_ type: NetworkType?) -> String {
    guard let type = type else { return "none" }
    switch type {
    case .wifi: return "WiFi"
    case .cellular: return "Cellular"
    case .other: return "Other"
    case .none: return "None"
    }
}

private func describeSpeed(_ speed: Int?) -> String {
    guard let speed else { return "none" }
    return "\(speed) km/h"
}

private func formatOptional(_ value: String?) -> String {
    guard let value, !value.isEmpty else { return "none" }
    return value
}

private func formatCountry(_ value: String?) -> String {
    guard let value = value, !value.isEmpty else { return "none" }
    return value.uppercased()
}
