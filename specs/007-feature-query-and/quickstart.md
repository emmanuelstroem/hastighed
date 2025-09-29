# Quickstart: GPKG Schema Analysis

## Overview
This quickstart demonstrates how to analyze GPKG file schemas and understand the data structure for speed limits, street names, hazards, and traffic surveillance.

## Prerequisites
- Python 3.9+ installed
- GPKG files available (denmark.gpkg, sweden.gpkg)
- Basic understanding of SQLite and spatial data

## Installation

### 1. Setup Python Environment
```bash
cd scripts
pip install -r requirements.txt
```

### 2. Make Script Executable
```bash
chmod +x gpkg_schema_analyzer.py
```

## Step-by-Step Analysis

### 1. Analyze Denmark GPKG File
```bash
python3 gpkg_schema_analyzer.py ../hastighed/gpkg/denmark.gpkg ./denmark_analysis
```

**Expected Output**:
```
Connected to GPKG file: ../hastighed/gpkg/denmark.gpkg
Found 10 tables: roads, rtree_roads_geom, rtree_traffic_geom, traffic, ...
Analyzing table: roads
...
JSON schema exported to: denmark_analysis/gpkg_schema.json
Markdown documentation exported to: denmark_analysis/gpkg_schema.md
CSV export saved to: denmark_analysis/gpkg_tables.csv
```

### 2. Analyze Sweden GPKG File
```bash
python3 gpkg_schema_analyzer.py ../hastighed/gpkg/sweden.gpkg ./sweden_analysis
```

### 3. Review Generated Documentation

#### JSON Schema (`gpkg_schema.json`)
```json
{
  "database_info": {
    "file_path": "../hastighed/gpkg/denmark.gpkg",
    "file_size_mb": 42.54,
    "tables_count": 18
  },
  "tables": {
    "roads": {
      "columns": [...],
      "row_count": 155573,
      "spatial_info": {
        "column_name": "geom",
        "geometry_type_name": "LINESTRING",
        "srs_id": 4326
      }
    }
  }
}
```

#### Markdown Documentation (`gpkg_schema.md`)
- Complete table descriptions
- Column information
- Sample queries
- Spatial metadata

#### CSV Export (`gpkg_tables.csv`)
- Tabular data for spreadsheet analysis
- Column-by-column breakdown
- Category classifications

## Key Findings

### Main Data Tables
1. **roads**: 155,573 road segments with speed limits and names
2. **traffic**: 1,842 surveillance points and cameras

### Speed Limit Data
- **Primary Column**: `maxspeed` (TEXT)
- **Additional Columns**: 
  - `maxspeed_advisory`
  - `maxspeed_variable`
  - `maxspeed_conditional`
  - `zone_maxspeed`

### Street Names
- **Column**: `name` (TEXT)
- **Coverage**: All road segments
- **Note**: Some segments may not have names

### Hazards
- **Column**: `hazard` (TEXT)
- **Content**: Hazard descriptions and warnings

### Traffic Surveillance
- **Table**: `traffic`
- **Geometry**: POINT locations
- **Equipment**: `man_made` column
- **Context**: Speed limits and signs at each location

## Sample Queries

### Speed Limit Query
```sql
-- Get speed limit within 5 meters of a point
SELECT maxspeed, name, highway, hazard
FROM roads 
WHERE ST_DWithin(geom, ST_Point(12.5683, 55.6761), 0.00005)
ORDER BY ST_Distance(geom, ST_Point(12.5683, 55.6761))
LIMIT 1;
```

### Street Name Query
```sql
-- Get street names near a location
SELECT name, highway, maxspeed
FROM roads 
WHERE name IS NOT NULL 
AND ST_DWithin(geom, ST_Point(12.5683, 55.6761), 0.0001)
ORDER BY ST_Distance(geom, ST_Point(12.5683, 55.6761));
```

### Hazard Query
```sql
-- Get hazards near a location
SELECT hazard, name, maxspeed
FROM roads 
WHERE hazard IS NOT NULL 
AND ST_DWithin(geom, ST_Point(12.5683, 55.6761), 0.0001)
ORDER BY ST_Distance(geom, ST_Point(12.5683, 55.6761));
```

### Traffic Surveillance Query
```sql
-- Get surveillance cameras near a location
SELECT name, man_made, maxspeed, sign
FROM traffic 
WHERE ST_DWithin(geom, ST_Point(12.5683, 55.6761), 0.0001)
ORDER BY ST_Distance(geom, ST_Point(12.5683, 55.6761));
```

## Integration with Swift/iOS

### Database Connection
```swift
import SQLite3

let dbPath = Bundle.main.path(forResource: "denmark", ofType: "gpkg")
var db: OpaquePointer?
sqlite3_open(dbPath, &db)
```

### Spatial Query with GEOSwift
```swift
import GEOSwift

let queryPoint = try Point(x: 12.5683, y: 55.6761)
let searchRadius = 0.00005 // ~5 meters

// Query for speed limits
let query = """
SELECT maxspeed, name, highway, hazard
FROM roads 
WHERE ST_DWithin(geom, ST_Point(?, ?), ?)
ORDER BY ST_Distance(geom, ST_Point(?, ?))
LIMIT 1
"""
```

## Performance Expectations

### Analysis Speed
- **Schema Analysis**: < 1 second per file
- **Documentation Generation**: < 5 seconds
- **Memory Usage**: < 10MB per file

### Query Performance
- **Spatial Queries**: < 100ms for 5-meter radius
- **R-tree Indexing**: Optimized for spatial operations
- **Caching**: Consider caching frequently accessed data

## Troubleshooting

### Common Issues
1. **File Not Found**: Check GPKG file path
2. **Permission Denied**: Ensure read access to GPKG files
3. **JSON Serialization**: Binary data handled automatically
4. **Missing Tables**: Script handles missing metadata tables

### Debug Information
- Enable verbose logging in the script
- Check generated CSV for detailed column information
- Review JSON schema for complete table structure

## Next Steps

1. **Implement Swift Integration**: Use schema information for iOS app
2. **Create Query Service**: Build service layer for GPKG queries
3. **Add Caching**: Implement query result caching
4. **Performance Testing**: Test query performance with real data
5. **Error Handling**: Implement robust error handling for edge cases

## Success Criteria
- ✅ Schema analysis completes successfully
- ✅ All data categories identified (speed limits, streets, hazards, surveillance)
- ✅ Documentation generated in multiple formats
- ✅ Sample queries provided for each data type
- ✅ Performance targets met (< 1 second analysis)
- ✅ Ready for Swift/iOS integration
