import Foundation
import CoreLocation

/// Cache for GPKG query results to improve performance
class GpkgQueryCache {
    
    // MARK: - Properties
    
    private var cache: [String: GpkgSpeedLimitResult] = [:]
    private let gridSize: Double = 0.0001 // ~10 meters in degrees
    private let maxCacheSize: Int = 1000
    private let accessOrder: [String] = []
    
    // MARK: - Cache Operations
    
    /// Get cached speed limit result for a coordinate
    func getSpeedLimit(for coordinate: CLLocationCoordinate2D) -> GpkgSpeedLimitResult? {
        let key = gridKey(for: coordinate)
        return cache[key]
    }
    
    /// Set cached speed limit result for a coordinate
    func setSpeedLimit(_ result: GpkgSpeedLimitResult, for coordinate: CLLocationCoordinate2D) {
        let key = gridKey(for: coordinate)
        
        // Implement LRU eviction if cache is full
        if cache.count >= maxCacheSize {
            evictLeastRecentlyUsed()
        }
        
        cache[key] = result
    }
    
    /// Clear all cached results
    func clearCache() {
        cache.removeAll()
    }
    
    /// Get cache statistics
    func getCacheStats() -> GpkgCacheStats {
        return GpkgCacheStats(
            size: cache.count,
            maxSize: maxCacheSize,
            hitRate: calculateHitRate(),
            memoryUsage: estimateMemoryUsage()
        )
    }
    
    // MARK: - Private Methods
    
    /// Generate a grid-based key for a coordinate
    private func gridKey(for coordinate: CLLocationCoordinate2D) -> String {
        let lat = Int(coordinate.latitude / gridSize)
        let lon = Int(coordinate.longitude / gridSize)
        return "\(lat),\(lon)"
    }
    
    /// Evict least recently used items from cache
    private func evictLeastRecentlyUsed() {
        // Simple implementation: remove 10% of cache
        let itemsToRemove = max(1, cache.count / 10)
        let keysToRemove = Array(cache.keys.prefix(itemsToRemove))
        
        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }
    }
    
    /// Calculate cache hit rate (simplified)
    private func calculateHitRate() -> Double {
        // In a real implementation, you'd track hits and misses
        return 0.0
    }
    
    /// Estimate memory usage of cache
    private func estimateMemoryUsage() -> Int64 {
        // Rough estimate: each result is ~1KB
        return Int64(cache.count * 1024)
    }
}

// MARK: - Cache Statistics

struct GpkgCacheStats {
    let size: Int
    let maxSize: Int
    let hitRate: Double
    let memoryUsage: Int64
    
    var utilizationPercentage: Double {
        return Double(size) / Double(maxSize) * 100.0
    }
    
    var isNearCapacity: Bool {
        return utilizationPercentage > 80.0
    }
}
