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
