import Foundation
import CoreLocation

struct UpcomingSpeedLimitChange: Identifiable, Hashable {
    let id = UUID()
    let newLimit: SpeedLimit
    let distanceMeters: Double
}

struct SpeedCamera: Identifiable, Hashable {
    enum CameraType { case fixed, mobile, average }
    let id = UUID()
    let type: CameraType
    let distanceMeters: Double
}

struct RoadHazard: Identifiable, Hashable {
    enum HazardType { case schoolZone, sharpTurn, roadworks }
    let id = UUID()
    let type: HazardType
    let distanceMeters: Double
}
