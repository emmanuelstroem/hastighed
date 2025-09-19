import Foundation
import CoreLocation

protocol SpeedLimitProviding {
    func currentSpeedLimit(for location: CLLocation?) -> SpeedLimit
}

/// Placeholder rules-based service.
final class SpeedLimitService: SpeedLimitProviding {
    
    /// Returns a basic fallback limit; improves as we add classification.
    func currentSpeedLimit(for location: CLLocation?) -> SpeedLimit {
        guard let location else {
            return SpeedLimit(kmh: 50, source: .ruleFallback, confidence: 0.3)
        }
        
        return SpeedLimit(kmh: 50, source: .ruleFallback, confidence: 0.4)
//        let country = location.isoCountryCode?.uppercased() ?? "XX"
//        // Ultra-simplified mapping
//        switch country {
//        case "DE": // Germany generic urban fallback
//            return SpeedLimit(kmh: 50, source: .ruleFallback, confidence: 0.4)
//        case "FR":
//            return SpeedLimit(kmh: 50, source: .ruleFallback, confidence: 0.4)
//        case "DK":
//            return SpeedLimit(kmh: 50, source: .ruleFallback, confidence: 0.4)
//        case "GB", "UK":
//            return SpeedLimit(kmh: 48, source: .ruleFallback, confidence: 0.35) // 30 mph ~ 48 km/h
//        default:
//            return SpeedLimit(kmh: 50, source: .ruleFallback, confidence: 0.25)
//        }
    }
}
