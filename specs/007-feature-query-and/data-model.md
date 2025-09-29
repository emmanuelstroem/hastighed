# Data Model: GPKG Schema Analysis

## GPKG File Structure Overview

Based on analysis of Denmark and Sweden GPKG files, the schema follows a consistent pattern with two main data tables and supporting spatial indexing tables.

### File Information
- **Denmark GPKG**: 42.54 MB, 18 tables, 155,573 road segments
- **Sweden GPKG**: 150.23 MB, 18 tables, similar structure
- **Spatial Reference System**: WGS84 (EPSG:4326)
- **Geometry Types**: LINESTRING (roads), POINT (traffic features)

## Main Data Tables

### 1. Roads Table
**Purpose**: Contains road segments with speed limits, names, and hazard information

**Columns**:
- `fid` (INTEGER, PRIMARY KEY): Unique feature identifier
- `geom` (LINESTRING): Road segment geometry
- `highway` (TEXT): Road type classification
- `maxspeed` (TEXT): Primary speed limit value
- `name` (TEXT): Street/road name
- `maxspeed_advisory` (TEXT): Advisory speed limit
- `maxspeed_variable` (TEXT): Variable speed limit
- `maxspeed_conditional` (TEXT): Conditional speed limit
- `zone_maxspeed` (TEXT): Zone-based speed limit
- `hazard` (TEXT): Hazard information
- `sign` (TEXT): Traffic sign information

**Key Features**:
- 155,573 road segments in Denmark
- Contains all speed limit variations
- Includes street names and hazard data
- Spatial geometry for precise location queries

### 2. Traffic Table
**Purpose**: Contains traffic surveillance points and cameras

**Columns**:
- `fid` (INTEGER, PRIMARY KEY): Unique feature identifier
- `geom` (POINT): Camera/surveillance point location
- `highway` (TEXT): Road type at location
- `man_made` (TEXT): Type of surveillance equipment
- `name` (TEXT): Location or equipment name
- `maxspeed` (TEXT): Speed limit at location
- `maxspeed_advisory` (TEXT): Advisory speed limit
- `maxspeed_variable` (TEXT): Variable speed limit
- `maxspeed_conditional` (TEXT): Conditional speed limit
- `zone_maxspeed` (TEXT): Zone-based speed limit
- `sign` (TEXT): Traffic sign information
- `hazard` (TEXT): Hazard information

**Key Features**:
- 1,842 surveillance points in Denmark
- Point geometry for precise camera locations
- Includes speed limit context at each location
- Contains surveillance equipment type information

## Spatial Indexing Tables

### R-Tree Index Tables
Each main table has 4 supporting R-tree index tables for efficient spatial queries:

1. **rtree_[table]_geom**: Bounding box coordinates
2. **rtree_[table]_geom_node**: R-tree node data
3. **rtree_[table]_geom_parent**: Parent-child relationships
4. **rtree_[table]_geom_rowid**: Row ID mappings

## Data Categories Identified

### Speed Limits
- **Primary Source**: `roads.maxspeed` and `traffic.maxspeed`
- **Additional Sources**: 
  - `maxspeed_advisory`
  - `maxspeed_variable` 
  - `maxspeed_conditional`
  - `zone_maxspeed`
- **Data Type**: TEXT (may contain values like "50", "30", "none", "variable")

### Street Names
- **Primary Source**: `roads.name` and `traffic.name`
- **Data Type**: TEXT
- **Coverage**: All road segments and traffic points

### Hazards
- **Primary Source**: `roads.hazard` and `traffic.hazard`
- **Data Type**: TEXT
- **Content**: Hazard descriptions and warnings

### Traffic Surveillance
- **Primary Source**: `traffic` table
- **Equipment Type**: `man_made` column
- **Location**: Point geometry (`geom`)
- **Context**: Speed limits and signs at surveillance points

## Query Patterns

### Speed Limit Queries
```sql
-- Get speed limits within 5 meters of a point
SELECT maxspeed, name, highway, hazard
FROM roads 
WHERE ST_DWithin(geom, ST_Point(?, ?), 0.00005)
ORDER BY ST_Distance(geom, ST_Point(?, ?))
LIMIT 1;
```

### Street Name Queries
```sql
-- Get street names near a location
SELECT name, highway, maxspeed
FROM roads 
WHERE name IS NOT NULL 
AND ST_DWithin(geom, ST_Point(?, ?), 0.0001)
ORDER BY ST_Distance(geom, ST_Point(?, ?));
```

### Hazard Queries
```sql
-- Get hazards near a location
SELECT hazard, name, maxspeed
FROM roads 
WHERE hazard IS NOT NULL 
AND ST_DWithin(geom, ST_Point(?, ?), 0.0001)
ORDER BY ST_Distance(geom, ST_Point(?, ?));
```

### Traffic Surveillance Queries
```sql
-- Get surveillance cameras near a location
SELECT name, man_made, maxspeed, sign
FROM traffic 
WHERE ST_DWithin(geom, ST_Point(?, ?), 0.0001)
ORDER BY ST_Distance(geom, ST_Point(?, ?));
```

## Data Quality Considerations

### Speed Limit Data
- Values stored as TEXT, may need parsing
- Multiple speed limit types available
- Some entries may be "none" or "variable"
- Zone-based limits may override segment limits

### Street Names
- Not all road segments have names
- Names may be in local language
- Highway classification provides context

### Spatial Accuracy
- WGS84 coordinate system (lat/lon)
- 5-meter search radius ≈ 0.00005 degrees
- R-tree indexing for efficient spatial queries

## Performance Characteristics

### Table Sizes
- **Denmark**: 155,573 road segments, 1,842 traffic points
- **Sweden**: Similar structure, larger file size
- **Index Tables**: Optimized for spatial queries

### Query Performance
- R-tree indexes enable fast spatial queries
- 5-meter radius queries should be < 100ms
- Consider caching frequently accessed data

## Integration Notes

### Swift/iOS Integration
- Use SQLite3 for database access
- GEOSwift for spatial geometry operations
- Spatial queries using ST_DWithin and ST_Distance
- Handle TEXT speed limits with proper parsing

### Data Validation
- Validate speed limit values before use
- Handle missing or null values gracefully
- Consider confidence levels based on data source
- Implement fallback strategies for missing data
