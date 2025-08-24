import Foundation
import CoreLocation
import os.log
import Combine

class OSMService: ObservableObject {
    private let logger = Logger(subsystem: "com.eopio.hastighed", category: "OSMService")
    private let fileManager = FileManager.default
    private var isDataLoaded = false
    
    // Simple data structure for speed limits
    private var speedLimitData: [SpeedLimitEntry] = []
    
    // Street tracking and update logic
    private var currentStreetName: String?
    private var lastStreetName: String?  // Track the last street name for periodic checks
    private var lastSpeedLimitCheck: Date = Date.distantPast
    private var lastKnownSpeedLimit: Int?
    private var updateTimer: Timer?
    private var currentLocation: CLLocation?  // Store current location from LocationManager
    
    @Published var currentSpeedLimit: Int?
    @Published var isLoadingSpeedLimit = false
    @Published var errorMessage: String?
    
    init() {
        loadGeoJSONData()
        setupUpdateTimer()
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    private func setupUpdateTimer() {
        // Check speed limit every 10 seconds for the same street
        updateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkSpeedLimitIfNeeded()
        }
    }
    
    private func checkSpeedLimitIfNeeded() {
        guard let streetName = currentStreetName else { return }
        
        // Only do periodic checks if we're on the same street as the last check
        guard streetName == self.lastStreetName else {
            logger.info("Periodic check skipped - street changed from '\(self.lastStreetName ?? "none")' to '\(streetName)'")
            return
        }
        
        // Only check if it's been more than 10 seconds since last check
        let timeSinceLastCheck = Date().timeIntervalSince(lastSpeedLimitCheck)
        if timeSinceLastCheck >= 10.0 {
            logger.info("Periodic speed limit check for street: \(streetName)")
            // Trigger a speed limit query through LocationManager
            NotificationCenter.default.post(name: .speedLimitCheckRequested, object: nil)
        } else {
            logger.info("Periodic check skipped - last check was \(String(format: "%.1f", timeSinceLastCheck))s ago")
        }
    }
    
    func updateStreetName(_ streetName: String) {
        let previousStreet = currentStreetName
        
        if previousStreet != streetName {
            logger.info("Street changed from '\(previousStreet ?? "none")' to '\(streetName)'")
            currentStreetName = streetName
            lastStreetName = streetName  // Update last street name
            
            // Street changed - check speed limit immediately
            if let location = getCurrentLocation() {
                querySpeedLimit(for: location)
            }
        } else {
            logger.info("Same street: \(streetName) - will check every 10 seconds")
        }
    }
    
    private func getCurrentLocation() -> CLLocation? {
        // Return the current location stored from LocationManager
        return currentLocation
    }
    
    func updateCurrentLocation(_ location: CLLocation) {
        currentLocation = location
    }
    
    func querySpeedLimit(for location: CLLocation) {
        guard isDataLoaded else {
            logger.warning("GeoJSON data not loaded")
            return
        }
        
        // Check if we need to update based on street change or time interval
        let shouldUpdate = shouldUpdateSpeedLimit(for: location)
        
        if !shouldUpdate {
            logger.info("Speed limit update skipped - same street and recent check")
            return
        }
        
        logger.info("Querying speed limit for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        logger.info("Total speed limit entries: \(self.speedLimitData.count)")
        
        isLoadingSpeedLimit = true
        
        // Find the nearest speed limit entry within 10 meters (reduced from 100m for better accuracy)
        if let nearestEntry = findNearestSpeedLimitEntry(to: location, maxRadius: 10.0) {
            let speedLimit = nearestEntry.speedLimit ?? getDefaultSpeed(for: nearestEntry.highwayType)
            
            // Check if speed limit has actually changed
            if speedLimit != lastKnownSpeedLimit {
                DispatchQueue.main.async {
                    self.currentSpeedLimit = speedLimit
                    self.isLoadingSpeedLimit = false
                    self.errorMessage = nil
                    self.lastKnownSpeedLimit = speedLimit
                    
                    // Store in UserDefaults
                    UserDefaults.standard.set(speedLimit, forKey: "currentSpeedLimit")
                    
                    self.logger.info("Speed limit updated: \(speedLimit) km/h (was: \(self.lastKnownSpeedLimit ?? 0))")
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoadingSpeedLimit = false
                }
                logger.info("Speed limit unchanged: \(speedLimit) km/h")
            }
            
            // Update last check time
            lastSpeedLimitCheck = Date()
            
        } else {
            DispatchQueue.main.async {
                self.currentSpeedLimit = nil
                self.isLoadingSpeedLimit = false
                self.errorMessage = "No road found within 10 meters"
                self.logger.warning("No road found within 10 meters of location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }
    }
    
    func querySpeedLimitImmediately(for location: CLLocation) {
        guard isDataLoaded else {
            logger.warning("GeoJSON data not loaded")
            return
        }
        
        logger.info("Immediate speed limit query on app launch for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        logger.info("Total speed limit entries: \(self.speedLimitData.count)")
        
        isLoadingSpeedLimit = true
        
        // Find the nearest speed limit entry within 10 meters (reduced from 100m for better accuracy)
        if let nearestEntry = findNearestSpeedLimitEntry(to: location, maxRadius: 10.0) {
            let speedLimit = nearestEntry.speedLimit ?? getDefaultSpeed(for: nearestEntry.highwayType)
            
            DispatchQueue.main.async {
                self.currentSpeedLimit = speedLimit
                self.isLoadingSpeedLimit = false
                self.errorMessage = nil
                self.lastKnownSpeedLimit = speedLimit
                
                // Store in UserDefaults
                UserDefaults.standard.set(speedLimit, forKey: "currentSpeedLimit")
                
                self.logger.info("Immediate speed limit found on app launch: \(speedLimit) km/h")
            }
            
            // Update last check time
            lastSpeedLimitCheck = Date()
            
        } else {
            DispatchQueue.main.async {
                self.currentSpeedLimit = nil
                self.isLoadingSpeedLimit = false
                self.errorMessage = "No road found within 10 meters on app launch"
                self.logger.warning("No road found within 10 meters on app launch: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }
    }
    
    private func shouldUpdateSpeedLimit(for location: CLLocation) -> Bool {
        // Always update if we don't have a speed limit yet
        guard currentSpeedLimit != nil else { return true }
        
        // Always update if street changed (this will be handled by updateStreetName)
        // We don't need to check here since street changes trigger immediate updates
        
        // Check if it's been more than 10 seconds since last check for the same street
        let timeSinceLastCheck = Date().timeIntervalSince(lastSpeedLimitCheck)
        return timeSinceLastCheck >= 10.0
    }
    
    private func loadGeoJSONData() {
        // First try to load from documents directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let geojsonPath = documentsPath.appendingPathComponent("denmark.geojson")
        
        // Check if file exists in documents directory
        if fileManager.fileExists(atPath: geojsonPath.path) {
            loadGeoJSONFromPath(geojsonPath)
            return
        }
        
        // Try to find the GeoJSON file in the bundle
        var bundlePath: String?
        
        // Try multiple possible locations
        if let path = Bundle.main.path(forResource: "denmark", ofType: "geojson") {
            // File is in the root of the bundle
            bundlePath = path
            logger.info("Found GeoJSON file in bundle root: \(path)")
        } else if let path = Bundle.main.path(forResource: "denmark", ofType: "geojson", inDirectory: "osm") {
            // File is in the "osm" subdirectory
            bundlePath = path
            logger.info("Found GeoJSON file in bundle osm subdirectory: \(path)")
        } else if let path = Bundle.main.path(forResource: "denmark", ofType: "geojson", inDirectory: nil) {
            // File is somewhere in the bundle
            bundlePath = path
            logger.info("Found GeoJSON file in bundle (no directory): \(path)")
        }
        
        // Debug: List all bundle resources
        if let resourcePath = Bundle.main.resourcePath {
            logger.info("Bundle resource path: \(resourcePath)")
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: resourcePath)
                logger.info("Bundle contents: \(contents)")
            } catch {
                logger.error("Failed to list bundle contents: \(error)")
            }
        }
        
        if let bundlePath = bundlePath {
            do {
                try fileManager.copyItem(atPath: bundlePath, toPath: geojsonPath.path)
                logger.info("Copied GeoJSON file from bundle to documents directory")
                loadGeoJSONFromPath(geojsonPath)
            } catch {
                logger.error("Failed to copy GeoJSON file: \(error)")
                setErrorMessage("Failed to copy GeoJSON file. Please ensure denmark.geojson is in the app's documents directory.")
            }
        } else {
            logger.error("GeoJSON file not found in bundle")
            setErrorMessage("GeoJSON file not found. Please copy denmark.geojson to the app's documents directory.")
        }
    }
    
    private func loadGeoJSONFromPath(_ path: URL) {
        do {
            let data = try Data(contentsOf: path)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            if let features = json?["features"] as? [[String: Any]] {
                parseFeatures(features)
                logger.info("GeoJSON loaded successfully. Total speed limit entries: \(self.speedLimitData.count)")
                self.isDataLoaded = true
                setErrorMessage(nil)
            } else {
                logger.error("Invalid GeoJSON format - no features found")
                setErrorMessage("Invalid GeoJSON format - no features found")
            }
            
        } catch {
            logger.error("Failed to load or parse GeoJSON file: \(error)")
            setErrorMessage("Failed to parse GeoJSON file: \(error.localizedDescription)")
        }
    }
    
    private func setErrorMessage(_ message: String?) {
        DispatchQueue.main.async {
            self.errorMessage = message
        }
    }
    
    private func parseFeatures(_ features: [[String: Any]]) {
        for feature in features {
            if let properties = feature["properties"] as? [String: Any],
               let geometry = feature["geometry"] as? [String: Any],
               let coordinates = geometry["coordinates"] as? [[Double]] {
                
                // Extract speed limit from properties
                var speedLimit: Int?
                if let maxspeed = properties["maxspeed"] as? String {
                    speedLimit = parseSpeedLimit(maxspeed)
                } else if let maxspeed = properties["max_speed"] as? String {
                    speedLimit = parseSpeedLimit(maxspeed)
                } else if let maxspeed = properties["speed_limit"] as? String {
                    speedLimit = parseSpeedLimit(maxspeed)
                }
                
                // Extract highway type for default speed
                let highwayType = properties["highway"] as? String ?? "unknown"
                
                // Create speed limit entry for each coordinate pair
                for coordinate in coordinates {
                    if coordinate.count >= 2 {
                        let entry = SpeedLimitEntry(
                            latitude: coordinate[1],
                            longitude: coordinate[0],
                            speedLimit: speedLimit,
                            highwayType: highwayType
                        )
                        speedLimitData.append(entry)
                    }
                }
            }
        }
    }
    
    private func findNearestSpeedLimitEntry(to location: CLLocation, maxRadius: Double) -> SpeedLimitEntry? {
        var nearestEntry: SpeedLimitEntry?
        var minDistance = Double.greatestFiniteMagnitude
        var totalEntries = 0
        var entriesWithinRadius = 0
        
        logger.info("Searching for speed limit entries within \(maxRadius)m of location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        logger.info("Total speed limit entries to search: \(self.speedLimitData.count)")
        
        for entry in speedLimitData {
            totalEntries += 1
            let entryLocation = CLLocation(latitude: entry.latitude, longitude: entry.longitude)
            let distance = location.distance(from: entryLocation)
            
            if distance <= maxRadius {
                entriesWithinRadius += 1
                if distance < minDistance {
                    minDistance = distance
                    nearestEntry = entry
                    logger.info("Found closer speed limit entry at distance: \(String(format: "%.2f", distance))m (highway: \(entry.highwayType), speed: \(entry.speedLimit ?? 0) km/h)")
                }
            }
            
            // Log progress every 1000 entries to avoid spam
            if totalEntries % 1000 == 0 {
                logger.info("Searched \(totalEntries) entries, found \(entriesWithinRadius) within radius")
            }
        }
        
        if nearestEntry != nil {
            logger.info("✅ Nearest speed limit entry found at distance: \(String(format: "%.2f", minDistance))m")
            logger.info("   Highway type: \(nearestEntry!.highwayType)")
            logger.info("   Speed limit: \(nearestEntry!.speedLimit ?? 0) km/h")
        } else {
            logger.warning("❌ No speed limit entry found within \(maxRadius)m radius")
            logger.info("   Searched \(totalEntries) total entries")
            logger.info("   Found \(entriesWithinRadius) entries within radius")
            
            // Log the closest entry even if it's outside the radius
            if minDistance != Double.greatestFiniteMagnitude {
                logger.info("   Closest entry was at \(String(format: "%.2f", minDistance))m (outside search radius)")
            }
        }
        
        return nearestEntry
    }
    
    private func parseSpeedLimit(_ speedString: String) -> Int? {
        // Handle different speed limit formats
        if let speed = Int(speedString) {
            return speed
        }
        
        // Handle "50 mph" format
        if speedString.contains("mph") {
            let mphString = speedString.replacingOccurrences(of: " mph", with: "")
            if let mph = Int(mphString) {
                return Int(Double(mph) * 1.60934) // Convert to km/h
            }
        }
        
        // Handle "50 km/h" format
        if speedString.contains("km/h") {
            let kmhString = speedString.replacingOccurrences(of: " km/h", with: "")
            return Int(kmhString)
        }
        
        // Handle "50" format (assume km/h)
        if let speed = Int(speedString.replacingOccurrences(of: " ", with: "")) {
            return speed
        }
        
        return nil
    }
    
    private func getDefaultSpeed(for highwayType: String) -> Int {
        switch highwayType.lowercased() {
        case "motorway":
            return 130
        case "trunk", "primary":
            return 80
        case "secondary":
            return 60
        case "tertiary":
            return 50
        case "residential", "unclassified":
            return 30
        case "service":
            return 30
        case "living_street":
            return 20
        default:
            return 50
        }
    }
    
    func getStoredSpeedLimit() -> Int? {
        return UserDefaults.standard.object(forKey: "currentSpeedLimit") as? Int
    }
    
    func refreshSpeedLimit() {
        // This method can be called to manually refresh the speed limit
        // It will use the last known location from LocationManager
        logger.info("Manual speed limit refresh requested")
    }
}

// Simple data structure for speed limit entries
struct SpeedLimitEntry {
    let latitude: Double
    let longitude: Double
    let speedLimit: Int?
    let highwayType: String
}

// Notification names for communication between LocationManager and OSMService
extension Notification.Name {
    static let speedLimitCheckRequested = Notification.Name("speedLimitCheckRequested")
}
