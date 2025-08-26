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
    
    func convertFromKmh(_ kmh: Double) -> Double {
        switch self {
        case .kmh: return kmh
        case .mph: return kmh * 0.621371
        }
    }
}

