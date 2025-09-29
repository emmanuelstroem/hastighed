import Foundation

/// Performance monitoring for GPKG operations
class GpkgPerformanceMonitor {
    
    // MARK: - Properties
    
    private var metrics: [GpkgPerformanceMetrics] = []
    private let maxMetricsCount: Int = 1000
    
    // MARK: - Performance Tracking
    
    /// Record a query performance metric
    func recordQuery(type: String, executionTime: TimeInterval, resultCount: Int) {
        let metric = GpkgPerformanceMetrics(
            queryType: type,
            executionTime: executionTime,
            resultCount: resultCount,
            memoryUsage: getCurrentMemoryUsage(),
            timestamp: Date()
        )
        
        metrics.append(metric)
        
        // Maintain metrics count limit
        if metrics.count > maxMetricsCount {
            metrics.removeFirst(metrics.count - maxMetricsCount)
        }
    }
    
    /// Get all performance metrics
    func getMetrics() -> [GpkgPerformanceMetrics] {
        return metrics
    }
    
    /// Get metrics for a specific query type
    func getMetrics(for queryType: String) -> [GpkgPerformanceMetrics] {
        return metrics.filter { $0.queryType == queryType }
    }
    
    /// Get recent metrics (last N queries)
    func getRecentMetrics(count: Int = 100) -> [GpkgPerformanceMetrics] {
        return Array(metrics.suffix(count))
    }
    
    /// Clear all metrics
    func clearMetrics() {
        metrics.removeAll()
    }
    
    // MARK: - Performance Analysis
    
    /// Get performance summary
    func getPerformanceSummary() -> GpkgPerformanceSummary {
        let totalQueries = metrics.count
        let averageExecutionTime = metrics.map { $0.executionTime }.reduce(0, +) / Double(max(totalQueries, 1))
        let totalExecutionTime = metrics.map { $0.executionTime }.reduce(0, +)
        
        let performanceGrade = calculateOverallGrade(averageTime: averageExecutionTime)
        
        return GpkgPerformanceSummary(
            totalQueries: totalQueries,
            averageExecutionTime: averageExecutionTime,
            totalExecutionTime: totalExecutionTime,
            performanceGrade: performanceGrade,
            slowestQuery: metrics.max { $0.executionTime < $1.executionTime },
            fastestQuery: metrics.min { $0.executionTime < $1.executionTime }
        )
    }
    
    /// Get performance breakdown by query type
    func getPerformanceBreakdown() -> [String: GpkgQueryTypeStats] {
        let groupedMetrics = Dictionary(grouping: metrics) { $0.queryType }
        
        return groupedMetrics.mapValues { metrics in
            let count = metrics.count
            let averageTime = metrics.map { $0.executionTime }.reduce(0, +) / Double(count)
            let minTime = metrics.map { $0.executionTime }.min() ?? 0
            let maxTime = metrics.map { $0.executionTime }.max() ?? 0
            
            return GpkgQueryTypeStats(
                queryType: metrics.first?.queryType ?? "unknown",
                count: count,
                averageExecutionTime: averageTime,
                minExecutionTime: minTime,
                maxExecutionTime: maxTime,
                performanceGrade: calculateGradeForTime(averageTime)
            )
        }
    }
    
    /// Get memory usage trends
    func getMemoryUsageTrend() -> [GpkgMemoryUsagePoint] {
        return metrics.map { metric in
            GpkgMemoryUsagePoint(
                timestamp: metric.timestamp,
                memoryUsage: metric.memoryUsage,
                queryType: metric.queryType
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// Get current memory usage
    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
    
    /// Calculate overall performance grade
    private func calculateOverallGrade(averageTime: TimeInterval) -> PerformanceGrade {
        switch averageTime {
        case 0..<0.001: return .excellent
        case 0.001..<0.01: return .good
        case 0.01..<0.1: return .acceptable
        default: return .poor
        }
    }
    
    /// Calculate grade for execution time
    private func calculateGradeForTime(_ time: TimeInterval) -> PerformanceGrade {
        switch time {
        case 0..<0.001: return .excellent
        case 0.001..<0.01: return .good
        case 0.01..<0.1: return .acceptable
        default: return .poor
        }
    }
}

// MARK: - Performance Data Structures

struct GpkgPerformanceSummary {
    let totalQueries: Int
    let averageExecutionTime: TimeInterval
    let totalExecutionTime: TimeInterval
    let performanceGrade: PerformanceGrade
    let slowestQuery: GpkgPerformanceMetrics?
    let fastestQuery: GpkgPerformanceMetrics?
    
    var formattedAverageTime: String {
        return String(format: "%.3f ms", averageExecutionTime * 1000)
    }
    
    var formattedTotalTime: String {
        return String(format: "%.3f ms", totalExecutionTime * 1000)
    }
}

struct GpkgQueryTypeStats {
    let queryType: String
    let count: Int
    let averageExecutionTime: TimeInterval
    let minExecutionTime: TimeInterval
    let maxExecutionTime: TimeInterval
    let performanceGrade: PerformanceGrade
    
    var formattedAverageTime: String {
        return String(format: "%.3f ms", averageExecutionTime * 1000)
    }
    
    var formattedMinTime: String {
        return String(format: "%.3f ms", minExecutionTime * 1000)
    }
    
    var formattedMaxTime: String {
        return String(format: "%.3f ms", maxExecutionTime * 1000)
    }
}

struct GpkgMemoryUsagePoint {
    let timestamp: Date
    let memoryUsage: Int64
    let queryType: String
    
    var formattedMemoryUsage: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: memoryUsage)
    }
}
