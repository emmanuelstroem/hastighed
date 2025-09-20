import Foundation
import CoreLocation

protocol UpcomingLimitProviding {
    func upcomingChanges(within meters: Double, from location: CLLocation) -> [UpcomingSpeedLimitChange]
}

protocol SpeedCameraProviding {
    func nearbyCameras(within meters: Double, from location: CLLocation) -> [SpeedCamera]
}

protocol RoadHazardProviding {
    func nearbyHazards(within meters: Double, from location: CLLocation) -> [RoadHazard]
}

// MARK: - Mock Implementations (Static Data)

final class MockUpcomingLimitProvider: UpcomingLimitProviding {
    func upcomingChanges(within meters: Double, from location: CLLocation) -> [UpcomingSpeedLimitChange] {
        let samples = [
            UpcomingSpeedLimitChange(newLimit: SpeedLimit(kmh: 30, source: .inferred, confidence: 0.5), distanceMeters: 180),
            UpcomingSpeedLimitChange(newLimit: SpeedLimit(kmh: 70, source: .inferred, confidence: 0.5), distanceMeters: 420) // filtered out for 250m window
        ]
        return samples.filter { $0.distanceMeters <= meters }.sorted { $0.distanceMeters < $1.distanceMeters }
    }
}

final class MockSpeedCameraProvider: SpeedCameraProviding {
    func nearbyCameras(within meters: Double, from location: CLLocation) -> [SpeedCamera] {
        let cams = [
            SpeedCamera(type: .fixed, distanceMeters: 250),
            SpeedCamera(type: .mobile, distanceMeters: 250) // filtered
        ]
        return cams.filter { $0.distanceMeters <= meters }.sorted { $0.distanceMeters < $1.distanceMeters }
    }
}

final class MockRoadHazardProvider: RoadHazardProviding {
    func nearbyHazards(within meters: Double, from location: CLLocation) -> [RoadHazard] {
        let hazards = [
            RoadHazard(type: .schoolZone, distanceMeters: 100),
            RoadHazard(type: .roadworks, distanceMeters: 250) // filtered
        ]
        return hazards.filter { $0.distanceMeters <= meters }.sorted { $0.distanceMeters < $1.distanceMeters }
    }
}
