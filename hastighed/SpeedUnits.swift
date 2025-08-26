import Foundation

enum SpeedUnits: String, CaseIterable, Identifiable {
    case kmh
    case mph
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .kmh: return "km/h"
        case .mph: return "mph"
        }
    }
    
    var unitSpeed: UnitSpeed { self == .kmh ? .kilometersPerHour : .milesPerHour }

    func convertFromKmh(_ kmh: Double) -> Double {
        Measurement(value: kmh, unit: .kilometersPerHour)
            .converted(to: unitSpeed)
            .value
    }

    func convertFromMetersPerSecond(_ mps: Double) -> Double {
        Measurement(value: mps, unit: .metersPerSecond)
            .converted(to: unitSpeed)
            .value
    }
}


enum SpeedResponse: String, CaseIterable, Identifiable {
    case instant
    case balanced
    case smooth

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instant: return "Instant"
        case .balanced: return "Balanced"
        case .smooth: return "Smooth"
        }
    }

    // Tuning parameters
    var emaAlpha: Double {
        switch self {
        case .instant: return 0.5
        case .balanced: return 0.3
        case .smooth: return 0.15
        }
    }

    var clampUnderMetersPerSecond: Double {
        switch self {
        case .instant: return 0.6 // ~2.2 km/h
        case .balanced: return 1.0 // ~3.6 km/h
        case .smooth: return 1.2 // ~4.3 km/h
        }
    }

    var displacementThresholdMeters: Double {
        switch self {
        case .instant: return 2.0
        case .balanced: return 3.0
        case .smooth: return 5.0
        }
    }

    var distanceFilterMeters: Double {
        switch self {
        case .instant: return 1.0
        case .balanced: return 3.0
        case .smooth: return 5.0
        }
    }
}

