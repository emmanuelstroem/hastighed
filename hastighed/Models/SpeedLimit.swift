import Foundation
import CoreLocation

/// Represents a speed limit value along with its provenance & confidence metric.
struct SpeedLimit: Hashable, Identifiable {
    enum Source: String {
        case ruleFallback   // Generic rule (e.g., country default) – lowest fidelity
        case inferred        // Derived heuristically from context
        case mapped          // From map / authoritative dataset
    }

    let id = UUID()
    let value: Measurement<UnitSpeed>
    let source: Source
    /// 0.0 – 1.0 expressing confidence in correctness.
    let confidence: Double

    init(kmh: Double, source: Source, confidence: Double) {
        self.value = Measurement(value: kmh, unit: UnitSpeed.kilometersPerHour)
        self.source = source
        self.confidence = max(0, min(confidence, 1))
    }
}

/// Represents a live speed reading.
struct SpeedReading: Hashable {
    let speed: Measurement<UnitSpeed>
    let timestamp: Date
    let horizontalAccuracy: CLLocationAccuracy?

    static func simulated(at speedKmh: Double) -> SpeedReading {
        SpeedReading(speed: Measurement(value: speedKmh, unit: .kilometersPerHour), timestamp: Date(), horizontalAccuracy: nil)
    }
}

/// Indicates relation between current speed and limit.
enum LimitStatus: Equatable {
    case below(delta: Measurement<UnitSpeed>)
    case near(delta: Measurement<UnitSpeed>) // within tolerance
    case over(delta: Measurement<UnitSpeed>)
}

extension LimitStatus {
    var isOver: Bool {
        if case .over = self { return true }
        return false
    }
}
