import Foundation
import CoreLocation
import Combine

protocol LocationServicing: AnyObject {
    var latestSpeed: Measurement<UnitSpeed>? { get }
    var latestLocation: CLLocation? { get }
    var speedPublisher: AnyPublisher<SpeedReading, Never> { get }
    func start()
    func stop()
}

final class LocationService: NSObject, LocationServicing {
    private let manager = CLLocationManager()
    private let subject = PassthroughSubject<SpeedReading, Never>()

    private(set) var latestLocation: CLLocation?
    private(set) var latestSpeed: Measurement<UnitSpeed>?

    private var isSimulating: Bool = false
    private var simulationTimer: Timer?
    private var simulatedSpeed: Double = 0

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .automotiveNavigation
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
    }

    var speedPublisher: AnyPublisher<SpeedReading, Never> { subject.eraseToAnyPublisher() }

    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            manager.startUpdatingLocation()
        default:
            startSimulationIfNeeded()
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        simulationTimer?.invalidate()
        simulationTimer = nil
    }

    private func startSimulationIfNeeded() {
        #if targetEnvironment(simulator)
        isSimulating = true
        simulationTimer?.invalidate()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            simulatedSpeed += 7 // ramp
            if simulatedSpeed > 140 { simulatedSpeed = 0 }
            let reading = SpeedReading.simulated(at: simulatedSpeed)
            latestSpeed = reading.speed
            subject.send(reading)
        }
        #endif
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        } else {
            startSimulationIfNeeded()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        latestLocation = loc
        if loc.speed >= 0 { // -1 means invalid
            let speedMps = loc.speed
            let speedKmh = speedMps * 3.6
            let reading = SpeedReading(speed: Measurement(value: speedKmh, unit: .kilometersPerHour), timestamp: Date(), horizontalAccuracy: loc.horizontalAccuracy)
            latestSpeed = reading.speed
            subject.send(reading)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // For MVP, fall back to simulation on failure
        startSimulationIfNeeded()
    }
}
