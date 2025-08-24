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
