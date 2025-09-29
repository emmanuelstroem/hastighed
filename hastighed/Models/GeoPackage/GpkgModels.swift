import Foundation
import CoreLocation

// MARK: - GPKG Database Models

/// Represents a road segment from the GPKG database
struct GpkgRoadSegment: Codable, Identifiable {
    let id: Int
    let geometry: String // WKT geometry string
    let highway: String?
    let maxspeed: String?
    let name: String?
    let maxspeedAdvisory: String?
    let maxspeedVariable: String?
    let maxspeedConditional: String?
    let zoneMaxspeed: String?
    let hazard: String?
    let sign: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "fid"
        case geometry = "geom"
        case highway
        case maxspeed
        case name
        case maxspeedAdvisory = "maxspeed_advisory"
        case maxspeedVariable = "maxspeed_variable"
        case maxspeedConditional = "maxspeed_conditional"
        case zoneMaxspeed = "zone_maxspeed"
        case hazard
        case sign
    }
}

/// Represents a traffic surveillance point from the GPKG database
struct GpkgTrafficPoint: Codable, Identifiable {
    let id: Int
    let geometry: String // WKT geometry string
    let highway: String?
    let manMade: String?
    let name: String?
    let maxspeed: String?
    let maxspeedAdvisory: String?
    let maxspeedVariable: String?
    let maxspeedConditional: String?
    let zoneMaxspeed: String?
    let sign: String?
    let hazard: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "fid"
        case geometry = "geom"
        case highway
        case manMade = "man_made"
        case name
        case maxspeed
        case maxspeedAdvisory = "maxspeed_advisory"
        case maxspeedVariable = "maxspeed_variable"
        case maxspeedConditional = "maxspeed_conditional"
        case zoneMaxspeed = "zone_maxspeed"
        case sign
        case hazard
    }
}

// MARK: - GPKG Query Results

/// Result of a spatial query for speed limits
struct GpkgSpeedLimitResult {
    let roadSegment: GpkgRoadSegment?
    let trafficPoint: GpkgTrafficPoint?
    let distance: Double // Distance in meters
    let confidence: Double // Confidence level 0.0-1.0
    let source: GpkgDataSource
    
    var speedLimit: String? {
        return roadSegment?.maxspeed ?? trafficPoint?.maxspeed
    }
    
    var streetName: String? {
        return roadSegment?.name ?? trafficPoint?.name
    }
    
    var hazardInfo: String? {
        return roadSegment?.hazard ?? trafficPoint?.hazard
    }
}

/// Data source for speed limit information
enum GpkgDataSource: String, CaseIterable {
    case roadSegment = "road_segment"
    case trafficPoint = "traffic_point"
    case fallback = "fallback"
}

// MARK: - GPKG Schema Information

/// Database schema information for a GPKG table
struct GpkgTableSchema: Codable {
    let tableName: String
    let columns: [GpkgColumnInfo]
    let rowCount: Int
    let spatialInfo: GpkgSpatialInfo?
    let category: GpkgTableCategory
    
    enum CodingKeys: String, CodingKey {
        case tableName = "table_name"
        case columns
        case rowCount = "row_count"
        case spatialInfo = "spatial_info"
        case category
    }
}

/// Column information for a GPKG table
struct GpkgColumnInfo: Codable {
    let name: String
    let type: String
    let notNull: Bool
    let primaryKey: Bool
    
    enum CodingKeys: String, CodingKey {
        case name
        case type
        case notNull = "not_null"
        case primaryKey = "primary_key"
    }
}

/// Spatial information for a GPKG table
struct GpkgSpatialInfo: Codable {
    let columnName: String
    let geometryType: String
    let srsId: Int
    
    enum CodingKeys: String, CodingKey {
        case columnName = "column_name"
        case geometryType = "geometry_type"
        case srsId = "srs_id"
    }
}

/// Table category for GPKG tables
enum GpkgTableCategory: String, CaseIterable, Codable {
    case speedLimits = "speed_limits"
    case streetNames = "street_names"
    case hazards = "hazards"
    case surveillance = "surveillance"
    case other = "other"
}

// MARK: - GPKG Database Information

/// Complete database information for a GPKG file
struct GpkgDatabaseInfo: Codable {
    let filePath: String
    let fileSizeBytes: Int
    let fileSizeMB: Double
    let gpkgVersion: String
    let tablesCount: Int
    let analysisDate: String
    let tables: [String: GpkgTableSchema]
    let spatialTables: [String: GpkgSpatialInfo]
    let categorizedTables: [GpkgTableCategory: [String]]
    
    enum CodingKeys: String, CodingKey {
        case filePath = "file_path"
        case fileSizeBytes = "file_size_bytes"
        case fileSizeMB = "file_size_mb"
        case gpkgVersion = "gpkg_version"
        case tablesCount = "tables_count"
        case analysisDate = "analysis_date"
        case tables
        case spatialTables = "spatial_tables"
        case categorizedTables = "categorized_tables"
    }
}

// MARK: - GPKG Query Configuration

/// Configuration for GPKG spatial queries
struct GpkgQueryConfig {
    let searchRadius: Double // in meters
    let maxResults: Int
    let includeGeometry: Bool
    let preferredTables: [String]
    let fallbackToCountryDefault: Bool
    
    nonisolated(unsafe) static let `default` = GpkgQueryConfig(
        searchRadius: 5.0,
        maxResults: 1,
        includeGeometry: false,
        preferredTables: ["roads", "traffic"],
        fallbackToCountryDefault: true
    )
}

// MARK: - GPKG Performance Metrics

/// Performance metrics for GPKG operations
struct GpkgPerformanceMetrics {
    let queryType: String
    let executionTime: TimeInterval
    let resultCount: Int
    let memoryUsage: Int64
    let timestamp: Date
    
    var performanceGrade: PerformanceGrade {
        switch executionTime {
        case 0..<0.001:
            return .excellent
        case 0.001..<0.01:
            return .good
        case 0.01..<0.1:
            return .acceptable
        default:
            return .poor
        }
    }
}

enum PerformanceGrade: String, CaseIterable {
    case excellent = "A"
    case good = "B"
    case acceptable = "C"
    case poor = "D"
}

// MARK: - Extensions

extension GpkgRoadSegment {
    /// Check if geometry is a valid WKT string
    func hasValidGeometry() -> Bool {
        guard !geometry.isEmpty else { return false }
        return geometry.contains("LINESTRING") || geometry.contains("POINT")
    }
}

extension GpkgTrafficPoint {
    /// Check if geometry is a valid WKT string
    func hasValidGeometry() -> Bool {
        guard !geometry.isEmpty else { return false }
        return geometry.contains("POINT")
    }
}

extension GpkgSpeedLimitResult {
    /// Get the most relevant speed limit value
    var primarySpeedLimit: String? {
        // Priority: maxspeed > maxspeed_advisory > maxspeed_variable > maxspeed_conditional > zone_maxspeed
        if let maxspeed = roadSegment?.maxspeed ?? trafficPoint?.maxspeed, !maxspeed.isEmpty {
            return maxspeed
        }
        if let advisory = roadSegment?.maxspeedAdvisory ?? trafficPoint?.maxspeedAdvisory, !advisory.isEmpty {
            return advisory
        }
        if let variable = roadSegment?.maxspeedVariable ?? trafficPoint?.maxspeedVariable, !variable.isEmpty {
            return variable
        }
        if let conditional = roadSegment?.maxspeedConditional ?? trafficPoint?.maxspeedConditional, !conditional.isEmpty {
            return conditional
        }
        if let zone = roadSegment?.zoneMaxspeed ?? trafficPoint?.zoneMaxspeed, !zone.isEmpty {
            return zone
        }
        return nil
    }
    
    /// Check if this is a variable speed limit
    var isVariableSpeedLimit: Bool {
        return (roadSegment?.maxspeedVariable ?? trafficPoint?.maxspeedVariable) != nil
    }
    
    /// Check if this is a conditional speed limit
    var isConditionalSpeedLimit: Bool {
        return (roadSegment?.maxspeedConditional ?? trafficPoint?.maxspeedConditional) != nil
    }
}
