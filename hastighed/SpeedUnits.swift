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


 

