## Speedometer Responsiveness and Accuracy

- [ ] Consider dynamic smoothing: increase responsiveness (higher alpha) at higher speeds and reduce jitter at low speeds.
- [ ] Gate zeroing with Core Motion activity to clamp stationary jitter confidently.
- [ ] Add a setting to toggle animations on the dial for users who prefer smooth vs. instant.
- [ ] Add a performance test that simulates 10 Hz speed updates to ensure the UI stays under 16 ms per frame.

# TODO

## Phase 2 Enhancements (Completed ✅)

### Real OSM Data Implementation
- [x] Basic data structure for OSM ways and nodes
- [x] Spatial indexing system for efficient querying
- [x] Speed limit extraction from way tags
- [x] Fallback speed limits based on road type
- [x] Distance-based road finding
- [x] Grid-based spatial indexing
- [x] Search radius optimization (1000m)
- [x] Enhanced debugging and logging
- [x] Remove geofencing and predefined segments
- [x] Create comprehensive test data covering major Danish cities
- [x] Add fallback mechanism for spatial indexing failures
- [x] Improve debugging with detailed location and grid cell logging
- [x] **COMPLETED: Integrate GeoJSON parsing instead of PBF**
- [x] **COMPLETED: Replace test data with actual parsed GeoJSON data**
- [x] **COMPLETED: Implement 5-meter radius for speed limit queries**
- [x] **COMPLETED: Implement intelligent speed limit update logic**

### Intelligent Speed Limit Update Logic
- [x] Show speed limit at current street address
- [x] Listen to address changes
- [x] If street is the same, check speed limit every 10 seconds
- [x] If street is different, check speed limit immediately
- [x] If speed limit is different than current one, update UI immediately
- [x] Otherwise, just write a log message
- [x] Implement notification system between LocationManager and OSMService
- [x] Add timer-based periodic checking for same street
- [x] Optimize update frequency to prevent unnecessary queries
- [x] **COMPLETED: Immediate speed limit display on app launch**
- [x] **COMPLETED: Fix periodic speed limit checking when street hasn't changed**
- [x] **COMPLETED: Fix search radius issue for speed limit queries (5m → 100m → 10m optimized)**
- [x] **COMPLETED: Implement MBTiles support for efficient speed limit queries (replaces 8.6M entry search)**
- [x] **COMPLETED: Optimize MBTiles zoom levels and implement multi-zoom fallback for better coverage**

### Speed Limit Accuracy
- [x] Query actual road segments instead of generated data
- [x] Use real GeoJSON data from OpenStreetMap
- [x] Implement 5-meter radius for precise location matching
- [x] Add fallback speed limits based on road type

### Performance Optimization
- [x] Implement intelligent querying based on street changes
- [x] Reduce unnecessary speed limit queries
- [x] Add periodic checking with configurable intervals
- [x] Optimize data loading and parsing

### User Experience Improvements
- [x] Keep screen awake when app is running
- [x] Provide immediate feedback on street changes
- [x] Reduce "Detecting..." states
- [x] Implement efficient update logic

## Future Enhancements

### Phase 3: Advanced Features
- [ ] Speed camera integration
- [ ] Construction zone detection
- [ ] Traffic pattern analysis
- [ ] Route optimization with speed limits

### Performance and Reliability
- [ ] Add caching for frequently accessed speed limits
- [ ] Implement background refresh capabilities
- [ ] Add offline map support
- [ ] Optimize memory usage for large datasets

### User Interface
- [ ] Add speed limit history
- [ ] Implement speed limit alerts
- [ ] Add route planning with speed limit consideration
- [ ] Enhanced map visualization

### Speed Accuracy & Smoothing
- [ ] Add setting: "Speedometer response" (Instant vs Smooth)
- [ ] Expose thresholds (EMA alpha, clamp m/s, displacement meters) in a config file
- [ ] Integrate Core Motion `CMMotionActivity` to gate stationary/walking vs driving
- [ ] Consider Kalman filter for speed estimation (replace/augment EMA)
- [ ] Make `distanceFilter` adaptive based on speed and accuracy
- [ ] Add unit tests for speed smoothing helper (extract logic for testability)
- [ ] Add UI test cases simulating jitter via the harness to validate clamping
- [ ] Set `pausesLocationUpdatesAutomatically = false` and measure impact
- [ ] Add in‑app diagnostics toggle to log raw vs derived vs smoothed speed

## Completed Tasks

- [x] **Integrate GeoJSON parsing instead of PBF** - Replaced PBF with GeoJSON for better compatibility
- [x] **Replace test data with actual parsed GeoJSON data** - Implemented real data parsing
- [x] **Implement 5-meter radius for speed limit queries** - Added precise radius-based searching
- [x] **Implement robust GeoJSON file loading (documents/bundle fallback)** - Added fallback loading mechanism
- [x] **Provide clear instructions for GeoJSON file placement** - Documented file placement requirements
- [x] **Show speed limit at current street address** - Implemented street-based speed limit display
- [x] **Listen to address changes** - Added address change detection
- [x] **If street is the same, check speed limit every 10 seconds** - Implemented periodic checking for same street
- [x] **If street is different, check speed limit immediately** - Added immediate checking for new streets
- [x] **If speed limit is different than current one, update UI immediately** - Implemented smart UI updates
- [x] **Otherwise, just write a log message** - Added logging for unchanged speed limits
- [x] **Implement notification system between LocationManager and OSMService** - Added notification-based communication
- [x] **Add timer-based periodic checking for same street** - Implemented timer-based updates
- [x] **Optimize update frequency to prevent unnecessary queries** - Reduced unnecessary API calls
- [x] **Immediate speed limit display on app launch** - Added launch-time speed limit query
- [x] **Fix periodic speed limit checking when street hasn't changed** - Resolved unnecessary periodic updates
- [x] **Fix search radius issue for speed limit queries (5m → 100m → 10m optimized)** - Optimized search radius
- [x] **Implement MBTiles support for efficient speed limit queries (replaces 8.6M entry search)** - Replaced GeoJSON with MBTiles
- [x] **Optimize MBTiles zoom levels and implement multi-zoom fallback for better coverage** - Added zoom level optimization
- [x] **Fix tile coordinate calculation for accurate MBTiles queries** - Fixed Y-coordinate calculation using Web Mercator projection
- [x] **Implement closest tile selection instead of center tile fallback** - Added intelligent tile selection based on actual location proximity
- [x] **Enhance speed limit parsing patterns for better data extraction** - Added support for km/h, mph formats and improved regex patterns
- [x] **Clean up unused code and simplify MBTiles implementation** - Removed multi-zoom fallback logic, unused debugging code, and streamlined the service for better performance and maintainability
- [x] **Enhance binary vector tile parsing support** - Added comprehensive parsing for both text-based and binary vector tile formats, eliminating the "Could not convert tile data to string" warning and improving speed limit extraction from MBTiles
- [x] **Implement intelligent multi-zoom fallback strategy** - Added automatic fallback to different zoom levels when calculated coordinates are outside available bounds, with intelligent bounds checking and tile validation for more accurate speed limit detection
