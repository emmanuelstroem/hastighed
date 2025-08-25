# Issues

## Current Issues

### GeoJSON File Loading
- **Status**: Resolved ✅
- **Description**: Successfully implemented GeoJSON file loading from the app bundle's "osm" subdirectory.
- **Solution**: Using standard JSONSerialization to parse GeoJSON features and extract speed limit data.

### Speed Limit Query Implementation
- **Status**: Resolved ✅
- **Description**: Successfully implemented intelligent speed limit querying using device location with a 5-meter radius and smart update logic.
- **Solution**: Created a system that tracks street changes, updates speed limits immediately when streets change, and checks every 10 seconds for the same street.

### Data Structure and Parsing
- **Status**: Resolved ✅
- **Description**: Successfully created a simple data structure for speed limit entries and implemented robust parsing.
- **Solution**: Using `SpeedLimitEntry` structs with latitude, longitude, speed limit, and highway type information.

### Intelligent Update Logic
- **Status**: Resolved ✅
- **Description**: Successfully implemented the requested logic for intelligent speed limit updates.
- **Solution**: 
  - Shows speed limit at current street address
  - Listens to address changes
  - If street is the same, checks speed limit every 10 seconds
  - If street is different, checks speed limit immediately
  - If speed limit is different than current one, updates UI immediately
  - Otherwise, just writes a log message

### Immediate Speed Limit Display on App Launch
- **Status**: Resolved ✅
- **Description**: Successfully implemented immediate speed limit display as soon as the app launches.
- **Solution**: 
  - App now queries for speed limit immediately when location services start
  - Uses `querySpeedLimitImmediately` method to bypass normal update logic on app launch
  - Provides instant value to users without waiting for movement or street changes
  - Maintains the intelligent update system for subsequent location changes

### Screen Wake Functionality
- **Status**: Resolved ✅
- **Description**: Successfully implemented screen wake functionality to prevent the screen from sleeping when the app is running.
- **Solution**: Added `UIApplication.shared.isIdleTimerDisabled = true` in the app delegate.

### MBTiles Implementation for Efficient Speed Limit Queries
- **Status**: Resolved ✅
- **Description**: Successfully replaced the inefficient GeoJSON approach (which searched through 8.6 million entries) with MBTiles support for much faster and more efficient speed limit queries.
- **Solution**: 
  - Created new `MBTilesService.swift` that uses SQLite3 to query only the specific tile needed for the current viewport/location
  - Implemented tile-based coordinate system (zoom level 12) for precise location mapping
  - Added proper MBTiles database loading from app bundle with fallback to documents directory
  - Integrated with existing LocationManager for seamless speed limit updates
  - **Result**: Instead of searching through millions of entries, the app now only loads the specific tile needed, dramatically improving performance
  - **Zoom Level Optimization**: Adjusted from zoom level 14 to 12 for better coverage of speed limit data
  - **Multi-Zoom Fallback**: Implemented fallback to try multiple zoom levels (12, 11, 10, 13, 14) if the primary zoom level doesn't contain data
  - **Enhanced Parsing**: Improved vector tile parsing to handle multiple speed limit formats and highway types for default speed limits
- **Files Modified**: 
  - `hastighed/services/MBTilesService.swift` (new file)
  - `hastighed/LocationManager.swift` (updated to use MBTilesService)
  - `hastighed/HomeView.swift` (added debug functionality)
  - `hastighed.xcodeproj/project.pbxproj` (updated to include denmark.mbtiles)
- **Performance Improvement**: From searching 8.6M entries to querying only the relevant tile data
- **Date**: August 25, 2025

### Search Radius Issue for Speed Limit Queries
- **Status**: Resolved ✅
- **Description**: The app was failing to find speed limit entries because the search radius was too small (5 meters). GeoJSON road data has coordinate points that are typically spaced much further apart (e.g., 100+ meters between points).
- **Solution**: 
  - Initially increased search radius from 5 meters to 100 meters for better coverage
  - **Optimized to 10 meters** based on actual data analysis showing entries as close as 5.81m
  - Added comprehensive logging to track search progress and distance calculations
  - Enhanced debugging to show exactly how many entries are found within the search radius
  - Added progress logging every 1000 entries to avoid console spam
  - **Result**: Much more efficient and accurate speed limit detection with minimal unnecessary searching

### Periodic Speed Limit Checking Issue
- **Status**: Resolved ✅
- **Description**: The app was doing periodic speed limit checks every 10 seconds even when the street hadn't changed, causing the UI to jump back to "Detecting..." unnecessarily.
- **Solution**: 
  - Fixed the `shouldUpdateSpeedLimit` method to only update when the street actually changes
  - Added tracking for the last street name to prevent unnecessary periodic checks
  - Modified the timer logic to only check when on the same street and it's been more than 10 seconds
  - Added proper location tracking between LocationManager and OSMService

## Resolved Issues

### OSM PBF Parsing Implementation
- **Status**: Resolved ✅
- **Description**: Successfully replaced PBF parsing with GeoJSON parsing for better reliability and performance.
- **Solution**: Implemented clean GeoJSON parsing using standard JSONSerialization.

### Speed Limit Query Frequency
- **Status**: Resolved ✅
- **Description**: Successfully implemented intelligent querying that balances responsiveness with performance.
- **Solution**: Immediate updates on street changes, periodic updates every 10 seconds for the same street.

### Offline Data Management
- **Status**: Resolved ✅
- **Description**: Successfully implemented offline GeoJSON data loading and management.
- **Solution**: GeoJSON file is loaded from the app bundle and cached in the documents directory.

## MBTiles Implementation for Efficient Speed Limit Queries

**Status**: Resolved ✅

**Issue**: The GeoJSON approach was too slow, searching through 8.6M entries to find 1 record.

**Solution**: 
- Replaced `OSMService.swift` with `MBTilesService.swift`
- Uses MBTiles (Mapbox Vector Tiles) for efficient tile-based data access
- Implements SQLite3 integration for database access
- Uses tile coordinate system (zoom level 12) for precise location queries
- Robust database loading with documents/bundle fallback
- Integrated with `LocationManager` for seamless operation

**Key Features**:
- **Zoom Level Optimization**: Changed from zoom 14 to 12 for better coverage
- **Multi-Zoom Fallback**: Tries multiple zoom levels [12, 11, 10, 13, 14] if primary fails
- **Enhanced Parsing**: Multiple speed limit patterns and highway type defaults
- **Nearest Tile Search**: Searches for nearby tiles if exact coordinates don't exist
- **Intelligent Coordinate Calculation**: Uses Web Mercator projection for accurate tile mapping
- **Metadata Fallback**: Falls back to metadata table for default speed limits when needed

**Recent Improvements**:
- **Fixed Y-Coordinate Calculation**: Corrected Web Mercator projection formula for accurate tile coordinates
- **Enhanced Binary Vector Tile Parsing**: Added comprehensive parsing for both text-based and binary vector tile formats
- **Multi-Zoom Fallback Strategy**: When calculated coordinates are outside available bounds, automatically tries different zoom levels to find valid tiles
- **Improved Tile Selection**: Finds the closest available tile to the actual location instead of just using center coordinates
- **Code Cleanup**: Removed unused multi-zoom logic and simplified the implementation for better performance

**Technical Details**:
- **Database**: SQLite3 integration for MBTiles access
- **Tile System**: Web Mercator projection with zoom level 12 as primary
- **Fallback Strategy**: [12, 11, 10, 13, 14] zoom levels with intelligent bounds checking
- **Parsing**: UTF-8, ASCII, and ISO Latin-1 encoding support for vector tile data
- **Performance**: Tile-based queries instead of full dataset scanning

## Binary Vector Tile Parsing Enhancement

**Status**: Resolved ✅

**Issue**: Warning "Could not convert tile data to string - might be binary vector tile format" was appearing in logs, indicating that MBTiles contain binary data that couldn't be parsed as plain text.

**Solution**: 
- Enhanced `parseVectorTileData` method to handle both text-based and binary vector tile formats
- Added binary pattern searching for speed limit information within binary data
- Implemented fallback parsing that looks for speed limit patterns in surrounding binary data
- Maintained backward compatibility with text-based tiles
- Added comprehensive logging for both parsing approaches

**Key Features**:
- **Dual Format Support**: Handles both UTF-8 text and binary vector tile data
- **Binary Pattern Matching**: Searches for speed limit keywords within binary data
- **Context-Aware Extraction**: Analyzes surrounding data to find speed values
- **Graceful Fallback**: Falls back to metadata table if no speed limit found in tile data
- **Enhanced Logging**: Provides detailed information about parsing approach used

## Code Cleanup and Simplification

**Status**: Resolved ✅

**Issue**: The MBTiles implementation had accumulated unnecessary complexity with multi-zoom fallback logic and unused debugging code.

**Solution**: 
- Removed unused multi-zoom fallback system (was trying zoom levels [12, 11, 10, 13, 14])
- Eliminated complex database debugging code that was not needed in production
- Removed unused `findNearestAvailableTile` method
- Simplified the tile query logic to use only zoom level 12 with intelligent fallback
- Streamlined the codebase for better maintainability and performance

**Key Improvements**:
- **Single Zoom Level**: Now uses only zoom level 12 for consistent performance
- **Simplified Fallback**: Only falls back to finding the closest available tile when exact coordinates fail
- **Cleaner Code**: Removed ~100 lines of unused debugging and multi-zoom logic
- **Better Performance**: Eliminated unnecessary database queries and coordinate calculations
- **Maintainability**: Code is now easier to understand and modify
