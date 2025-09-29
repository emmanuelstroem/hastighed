import Foundation
import CoreLocation
import SQLite3

/// Service for querying GeoPackage databases using SQLite3 for spatial operations
@MainActor
class GpkgQueryService {
    
    // MARK: - Properties
    
    private var database: OpaquePointer?
    private let queryConfig: GpkgQueryConfig
    private let performanceMonitor = GpkgPerformanceMonitor()
    
    // MARK: - Initialization
    
    @MainActor init(config: GpkgQueryConfig? = nil) {
        self.queryConfig = config ?? .default
    }
    
    @MainActor deinit {
        closeDatabase()
    }
    
    // MARK: - Database Management
    
    /// Open a GPKG database file
    func openDatabase(at path: String) throws {
        closeDatabase()
        
        let result = sqlite3_open_v2(path, &database, SQLITE_OPEN_READONLY, nil)
        guard result == SQLITE_OK else {
            throw GpkgError.databaseOpenFailed(String(cString: sqlite3_errmsg(database)))
        }
    }
    
    /// Close the current database
    func closeDatabase() {
        if let database = database {
            sqlite3_close(database)
            self.database = nil
        }
    }
    
    /// Check if database is open
    var isOpen: Bool {
        return database != nil
    }
    
    // MARK: - Spatial Queries
    
    /// Query speed limit for a specific coordinate
    func querySpeedLimit(at coordinate: CLLocationCoordinate2D) async throws -> GpkgSpeedLimitResult? {
        guard database != nil else {
            throw GpkgError.databaseNotOpen
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let roadResult = try await queryRoadSegments(at: coordinate)
            let trafficResult: GpkgSpeedLimitResult? = roadResult == nil ? try await queryTrafficPoints(at: coordinate) : nil
            let result = roadResult ?? trafficResult
            
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordQuery(
                type: "speed_limit",
                executionTime: executionTime,
                resultCount: result != nil ? 1 : 0
            )
            
            return result
        } catch {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordQuery(
                type: "speed_limit_error",
                executionTime: executionTime,
                resultCount: 0
            )
            throw error
        }
    }
    
    /// Query road segments near a coordinate
    private func queryRoadSegments(at coordinate: CLLocationCoordinate2D) async throws -> GpkgSpeedLimitResult? {
        guard database != nil else {
            throw GpkgError.databaseNotOpen
        }
        
        let bbox = boundingBox(for: coordinate, radiusInMeters: queryConfig.searchRadius)
        
        let query = """
        SELECT roads.fid, roads.highway, roads.maxspeed, roads.name,
               roads.maxspeed_advisory, roads.maxspeed_variable, roads.maxspeed_conditional,
               roads.zone_maxspeed, roads.hazard, roads.sign,
               rtree_roads_geom.minX, rtree_roads_geom.maxX, rtree_roads_geom.minY, rtree_roads_geom.maxY
        FROM roads
        INNER JOIN rtree_roads_geom ON roads.fid = rtree_roads_geom.id
        WHERE roads.maxspeed IS NOT NULL AND roads.maxspeed != ''
          AND rtree_roads_geom.maxX >= ?
          AND rtree_roads_geom.minX <= ?
          AND rtree_roads_geom.maxY >= ?
          AND rtree_roads_geom.minY <= ?
        ORDER BY
          (( (rtree_roads_geom.minX + rtree_roads_geom.maxX) / 2.0 - ? ) * ( (rtree_roads_geom.minX + rtree_roads_geom.maxX) / 2.0 - ? )) +
          (( (rtree_roads_geom.minY + rtree_roads_geom.maxY) / 2.0 - ? ) * ( (rtree_roads_geom.minY + rtree_roads_geom.maxY) / 2.0 - ? ))
        LIMIT ?
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            throw GpkgError.queryPreparationFailed(String(cString: sqlite3_errmsg(database)))
        }
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_double(statement, 1, bbox.minLon)
        sqlite3_bind_double(statement, 2, bbox.maxLon)
        sqlite3_bind_double(statement, 3, bbox.minLat)
        sqlite3_bind_double(statement, 4, bbox.maxLat)
        sqlite3_bind_double(statement, 5, coordinate.longitude)
        sqlite3_bind_double(statement, 6, coordinate.longitude)
        sqlite3_bind_double(statement, 7, coordinate.latitude)
        sqlite3_bind_double(statement, 8, coordinate.latitude)
        sqlite3_bind_int(statement, 9, Int32(queryConfig.maxResults))
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            return nil
        }
        
        let minX = sqlite3_column_double(statement, 10)
        let maxX = sqlite3_column_double(statement, 11)
        let minY = sqlite3_column_double(statement, 12)
        let maxY = sqlite3_column_double(statement, 13)
        let centerLongitude = (minX + maxX) / 2.0
        let centerLatitude = (minY + maxY) / 2.0
        let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
        let distance = distanceInMeters(from: coordinate, to: centerCoordinate)
        
        let roadSegment = try parseRoadSegment(from: statement, centroid: centerCoordinate)
        
        return GpkgSpeedLimitResult(
            roadSegment: roadSegment,
            trafficPoint: nil,
            distance: distance,
            confidence: calculateConfidence(for: roadSegment, distance: distance),
            source: .roadSegment
        )
    }
    
    /// Query traffic points near a coordinate
    private func queryTrafficPoints(at coordinate: CLLocationCoordinate2D) async throws -> GpkgSpeedLimitResult? {
        guard database != nil else {
            throw GpkgError.databaseNotOpen
        }
        
        let bbox = boundingBox(for: coordinate, radiusInMeters: queryConfig.searchRadius)
        
        let query = """
        SELECT traffic.fid, traffic.highway, traffic.man_made, traffic.name, traffic.maxspeed,
               traffic.maxspeed_advisory, traffic.maxspeed_variable, traffic.maxspeed_conditional,
               traffic.zone_maxspeed, traffic.sign, traffic.hazard,
               rtree_traffic_geom.minX, rtree_traffic_geom.maxX, rtree_traffic_geom.minY, rtree_traffic_geom.maxY
        FROM traffic
        INNER JOIN rtree_traffic_geom ON traffic.fid = rtree_traffic_geom.id
        WHERE traffic.maxspeed IS NOT NULL AND traffic.maxspeed != ''
          AND rtree_traffic_geom.maxX >= ?
          AND rtree_traffic_geom.minX <= ?
          AND rtree_traffic_geom.maxY >= ?
          AND rtree_traffic_geom.minY <= ?
        ORDER BY
          (( (rtree_traffic_geom.minX + rtree_traffic_geom.maxX) / 2.0 - ? ) * ( (rtree_traffic_geom.minX + rtree_traffic_geom.maxX) / 2.0 - ? )) +
          (( (rtree_traffic_geom.minY + rtree_traffic_geom.maxY) / 2.0 - ? ) * ( (rtree_traffic_geom.minY + rtree_traffic_geom.maxY) / 2.0 - ? ))
        LIMIT ?
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            throw GpkgError.queryPreparationFailed(String(cString: sqlite3_errmsg(database)))
        }
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_double(statement, 1, bbox.minLon)
        sqlite3_bind_double(statement, 2, bbox.maxLon)
        sqlite3_bind_double(statement, 3, bbox.minLat)
        sqlite3_bind_double(statement, 4, bbox.maxLat)
        sqlite3_bind_double(statement, 5, coordinate.longitude)
        sqlite3_bind_double(statement, 6, coordinate.longitude)
        sqlite3_bind_double(statement, 7, coordinate.latitude)
        sqlite3_bind_double(statement, 8, coordinate.latitude)
        sqlite3_bind_int(statement, 9, Int32(queryConfig.maxResults))
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            return nil
        }
        
        let minX = sqlite3_column_double(statement, 11)
        let maxX = sqlite3_column_double(statement, 12)
        let minY = sqlite3_column_double(statement, 13)
        let maxY = sqlite3_column_double(statement, 14)
        let centerLongitude = (minX + maxX) / 2.0
        let centerLatitude = (minY + maxY) / 2.0
        let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
        let distance = distanceInMeters(from: coordinate, to: centerCoordinate)
        
        let trafficPoint = try parseTrafficPoint(from: statement, centroid: centerCoordinate)
        
        return GpkgSpeedLimitResult(
            roadSegment: nil,
            trafficPoint: trafficPoint,
            distance: distance,
            confidence: calculateConfidence(for: trafficPoint, distance: distance),
            source: .trafficPoint
        )
    }
    
    // MARK: - Helper Methods
    
    /// Enable spatial extensions for the database
    private func enableSpatialExtensions() throws {
        guard database != nil else {
            throw GpkgError.databaseNotOpen
        }
        
        // Load spatial extensions
        let loadSpatial = "SELECT load_extension('mod_spatialite')"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(database, loadSpatial, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    /// Parse a road segment from SQLite result
    private func parseRoadSegment(from statement: OpaquePointer?, centroid: CLLocationCoordinate2D) throws -> GpkgRoadSegment {
        let id = Int(sqlite3_column_int(statement, 0))
        let highway = sqlite3_column_text(statement, 1).map { String(cString: $0) }
        let maxspeed = sqlite3_column_text(statement, 2).map { String(cString: $0) }
        let name = sqlite3_column_text(statement, 3).map { String(cString: $0) }
        let maxspeedAdvisory = sqlite3_column_text(statement, 4).map { String(cString: $0) }
        let maxspeedVariable = sqlite3_column_text(statement, 5).map { String(cString: $0) }
        let maxspeedConditional = sqlite3_column_text(statement, 6).map { String(cString: $0) }
        let zoneMaxspeed = sqlite3_column_text(statement, 7).map { String(cString: $0) }
        let hazard = sqlite3_column_text(statement, 8).map { String(cString: $0) }
        let sign = sqlite3_column_text(statement, 9).map { String(cString: $0) }
        
        return GpkgRoadSegment(
            id: id,
            geometry: "POINT(\(centroid.longitude) \(centroid.latitude))",
            highway: highway,
            maxspeed: maxspeed,
            name: name,
            maxspeedAdvisory: maxspeedAdvisory,
            maxspeedVariable: maxspeedVariable,
            maxspeedConditional: maxspeedConditional,
            zoneMaxspeed: zoneMaxspeed,
            hazard: hazard,
            sign: sign
        )
    }
    
    /// Parse a traffic point from SQLite result
    private func parseTrafficPoint(from statement: OpaquePointer?, centroid: CLLocationCoordinate2D) throws -> GpkgTrafficPoint {
        let id = Int(sqlite3_column_int(statement, 0))
        let highway = sqlite3_column_text(statement, 1).map { String(cString: $0) }
        let manMade = sqlite3_column_text(statement, 2).map { String(cString: $0) }
        let name = sqlite3_column_text(statement, 3).map { String(cString: $0) }
        let maxspeed = sqlite3_column_text(statement, 4).map { String(cString: $0) }
        let maxspeedAdvisory = sqlite3_column_text(statement, 5).map { String(cString: $0) }
        let maxspeedVariable = sqlite3_column_text(statement, 6).map { String(cString: $0) }
        let maxspeedConditional = sqlite3_column_text(statement, 7).map { String(cString: $0) }
        let zoneMaxspeed = sqlite3_column_text(statement, 8).map { String(cString: $0) }
        let sign = sqlite3_column_text(statement, 9).map { String(cString: $0) }
        let hazard = sqlite3_column_text(statement, 10).map { String(cString: $0) }
        
        return GpkgTrafficPoint(
            id: id,
            geometry: "POINT(\(centroid.longitude) \(centroid.latitude))",
            highway: highway,
            manMade: manMade,
            name: name,
            maxspeed: maxspeed,
            maxspeedAdvisory: maxspeedAdvisory,
            maxspeedVariable: maxspeedVariable,
            maxspeedConditional: maxspeedConditional,
            zoneMaxspeed: zoneMaxspeed,
            sign: sign,
            hazard: hazard
        )
    }
    
    /// Calculate distance between coordinate and geometry
    private func calculateDistance(from coordinate: CLLocationCoordinate2D, to roadSegment: GpkgRoadSegment) -> Double {
        // For now, return a simple distance calculation
        // In a real implementation, you'd parse the WKT geometry and calculate actual distance
        return 0.0
    }
    
    /// Calculate distance between coordinate and traffic point
    private func calculateDistance(from coordinate: CLLocationCoordinate2D, to trafficPoint: GpkgTrafficPoint) -> Double {
        // For now, return a simple distance calculation
        // In a real implementation, you'd parse the WKT geometry and calculate actual distance
        return 0.0
    }
    
    /// Calculate confidence level for a result
    private func calculateConfidence(for roadSegment: GpkgRoadSegment, distance: Double) -> Double {
        // Higher confidence for closer results and more complete data
        let distanceFactor = max(0, 1.0 - (distance / queryConfig.searchRadius))
        let dataCompleteness = calculateDataCompleteness(for: roadSegment)
        return (distanceFactor + dataCompleteness) / 2.0
    }
    
    /// Calculate confidence level for a traffic point
    private func calculateConfidence(for trafficPoint: GpkgTrafficPoint, distance: Double) -> Double {
        let distanceFactor = max(0, 1.0 - (distance / queryConfig.searchRadius))
        let dataCompleteness = calculateDataCompleteness(for: trafficPoint)
        return (distanceFactor + dataCompleteness) / 2.0
    }
    
    /// Calculate data completeness for a road segment
    private func calculateDataCompleteness(for roadSegment: GpkgRoadSegment) -> Double {
        var completeness = 0.0
        if roadSegment.maxspeed != nil { completeness += 0.3 }
        if roadSegment.name != nil { completeness += 0.2 }
        if roadSegment.highway != nil { completeness += 0.2 }
        if roadSegment.hazard != nil { completeness += 0.1 }
        if roadSegment.sign != nil { completeness += 0.1 }
        if roadSegment.maxspeedAdvisory != nil { completeness += 0.1 }
        return completeness
    }
    
    /// Calculate data completeness for a traffic point
    private func calculateDataCompleteness(for trafficPoint: GpkgTrafficPoint) -> Double {
        var completeness = 0.0
        if trafficPoint.maxspeed != nil { completeness += 0.3 }
        if trafficPoint.name != nil { completeness += 0.2 }
        if trafficPoint.highway != nil { completeness += 0.2 }
        if trafficPoint.hazard != nil { completeness += 0.1 }
        if trafficPoint.sign != nil { completeness += 0.1 }
        if trafficPoint.manMade != nil { completeness += 0.1 }
        return completeness
    }
    
    // MARK: - Performance Monitoring
    
    /// Get performance metrics
    func getPerformanceMetrics() -> [GpkgPerformanceMetrics] {
        return performanceMonitor.getMetrics()
    }
    
    /// Clear performance metrics
    func clearPerformanceMetrics() {
        performanceMonitor.clearMetrics()
    }
}

// MARK: - Error Types

enum GpkgError: LocalizedError {
    case databaseNotOpen
    case databaseOpenFailed(String)
    case queryPreparationFailed(String)
    case queryExecutionFailed(String)
    case invalidGeometry(String)
    case spatialExtensionNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .databaseNotOpen:
            return "Database is not open"
        case .databaseOpenFailed(let message):
            return "Failed to open database: \(message)"
        case .queryPreparationFailed(let message):
            return "Failed to prepare query: \(message)"
        case .queryExecutionFailed(let message):
            return "Failed to execute query: \(message)"
        case .invalidGeometry(let message):
            return "Invalid geometry: \(message)"
        case .spatialExtensionNotAvailable:
            return "Spatial extensions not available"
        }
    }
}

/// Bounding box coordinates in WGS84
private struct BoundingBox {
    let minLat: Double
    let maxLat: Double
    let minLon: Double
    let maxLon: Double
}

/// Compute bounding box for a center coordinate and radius in meters
private func boundingBox(for coordinate: CLLocationCoordinate2D, radiusInMeters: Double) -> BoundingBox {
    // Approximate conversion: 1 degree latitude ~= 111_320 meters
    let metersPerDegreeLatitude = 111_320.0
    let deltaLat = radiusInMeters / metersPerDegreeLatitude

    // Longitude distance varies with latitude
    let latitudeRadians = coordinate.latitude * .pi / 180.0
    let metersPerDegreeLongitude = cos(latitudeRadians) * metersPerDegreeLatitude
    let deltaLon: Double
    if metersPerDegreeLongitude.isZero {
        deltaLon = 0
    } else {
        deltaLon = radiusInMeters / metersPerDegreeLongitude
    }

    return BoundingBox(
        minLat: coordinate.latitude - deltaLat,
        maxLat: coordinate.latitude + deltaLat,
        minLon: coordinate.longitude - deltaLon,
        maxLon: coordinate.longitude + deltaLon
    )
}

/// Calculate the distance in meters between two coordinates
private func distanceInMeters(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
    let earthRadius = 6_371_000.0 // meters

    let deltaLat = (destination.latitude - origin.latitude) * .pi / 180.0
    let deltaLon = (destination.longitude - origin.longitude) * .pi / 180.0

    let originLatRad = origin.latitude * .pi / 180.0
    let destinationLatRad = destination.latitude * .pi / 180.0

    let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
            sin(deltaLon / 2) * sin(deltaLon / 2) * cos(originLatRad) * cos(destinationLatRad)
    let c = 2 * atan2(sqrt(a), sqrt(1 - a))

    return earthRadius * c
}

