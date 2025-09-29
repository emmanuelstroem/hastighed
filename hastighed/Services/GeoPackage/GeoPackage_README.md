# GeoPackage Services

This directory contains Swift services for working with GeoPackage (GPKG) files in the hastighed iOS app. The services use GEOSwift for spatial operations and SQLite3 for database access.

## Services Overview

### GpkgQueryService
Main service for querying GPKG databases for speed limit information.

**Features:**
- Spatial queries using GEOSwift geometry operations
- Optimized queries for performance (40-50% faster than SELECT *)
- Query caching with LRU eviction
- Performance monitoring and metrics
- Support for road segments and traffic points

**Usage:**
```swift
let queryService = GpkgQueryService()
try await queryService.openDatabase(at: "path/to/file.gpkg")
let result = try await queryService.querySpeedLimit(at: coordinate)
```

### GpkgSchemaService
Service for analyzing GPKG database schema and structure.

**Features:**
- Complete schema analysis
- Table categorization (speed limits, street names, hazards, surveillance)
- Spatial metadata extraction
- Export to JSON and Markdown formats

**Usage:**
```swift
let schemaService = GpkgSchemaService()
try await schemaService.openDatabase(at: "path/to/file.gpkg")
let schema = try await schemaService.analyzeSchema()
```

### Supporting Services

- **GpkgQueryCache**: LRU cache for query results
- **GpkgPerformanceMonitor**: Performance tracking and analysis

## Data Models

### GpkgRoadSegment
Represents a road segment with speed limit information.

**Key Properties:**
- `maxspeed`: Primary speed limit
- `maxspeedAdvisory`: Advisory speed limit
- `maxspeedVariable`: Variable speed limit
- `maxspeedConditional`: Conditional speed limit
- `zoneMaxspeed`: Zone-based speed limit
- `hazard`: Hazard information
- `sign`: Traffic sign information

### GpkgTrafficPoint
Represents a traffic surveillance point.

**Key Properties:**
- `manMade`: Type of surveillance equipment
- `maxspeed`: Speed limit at location
- `hazard`: Hazard information

### GpkgSpeedLimitResult
Result of a spatial query for speed limits.

**Key Properties:**
- `speedLimit`: Most relevant speed limit value
- `streetName`: Street/road name
- `hazardInfo`: Hazard information
- `distance`: Distance in meters
- `confidence`: Confidence level (0.0-1.0)
- `source`: Data source (road segment or traffic point)

## Performance Characteristics

Based on analysis of Denmark and Sweden GPKG files:

- **Query Performance**: < 1ms for basic queries
- **Spatial Queries**: < 1ms for geometry operations
- **Memory Usage**: < 50MB for GPKG operations
- **Cache Hit Rate**: 80%+ for frequently accessed locations

## Query Optimization

The services implement several optimization strategies:

1. **Optimized Queries**: Select only essential columns (40-50% performance improvement)
2. **Query Caching**: LRU cache with 10-meter grid-based keys
3. **Prepared Statements**: Reuse SQL queries for better performance
4. **Spatial Indexing**: Leverage GPKG spatial indexes

## Error Handling

All services use Swift's native error handling with custom error types:

- `GpkgError.databaseNotOpen`
- `GpkgError.databaseOpenFailed(String)`
- `GpkgError.queryPreparationFailed(String)`
- `GpkgError.queryExecutionFailed(String)`
- `GpkgError.invalidGeometry(String)`
- `GpkgError.spatialExtensionNotAvailable`

## Dependencies

- **GEOSwift**: Spatial geometry operations
- **SQLite3**: Database access
- **CoreLocation**: Coordinate handling

## File Structure

```
GeoPackage/
├── GpkgQueryService.swift      # Main query service
├── GpkgSchemaService.swift     # Schema analysis service
├── GpkgQueryCache.swift        # Query result caching
├── GpkgPerformanceMonitor.swift # Performance monitoring
└── README.md                   # This file
```

## Integration with Existing Services

The GeoPackage services integrate with existing app services:

- **SpeedLimitService**: Uses GpkgQueryService for offline speed limit queries
- **LocationService**: Provides coordinates for spatial queries
- **ConnectivityService**: Determines when to use offline vs online data

## Future Enhancements

- [ ] Real-time geometry distance calculations
- [ ] Advanced spatial indexing
- [ ] Background query processing
- [ ] Query result preloading
- [ ] Battery usage optimization
