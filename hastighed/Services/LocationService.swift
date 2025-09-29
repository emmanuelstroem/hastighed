import Foundation
import CoreLocation
import Combine
import UIKit

protocol LocationServicing: AnyObject {
    var latestSpeed: Measurement<UnitSpeed>? { get }
    var latestLocation: CLLocation? { get }
    var latestCoordinate: CLLocationCoordinate2D? { get }
    var speedPublisher: AnyPublisher<SpeedReading, Never> { get }
    var coordinatePublisher: AnyPublisher<CLLocationCoordinate2D?, Never> { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    var authorizationPublisher: AnyPublisher<CLAuthorizationStatus, Never> { get }
    func requestAuthorization()
    func start()
    func stop()
    func openAppSettings()
}

final class LocationService: NSObject, LocationServicing {
    private let manager = CLLocationManager()
    private let subject = PassthroughSubject<SpeedReading, Never>()
    private let authSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)
    private let coordinateSubject = CurrentValueSubject<CLLocationCoordinate2D?, Never>(nil)

    private(set) var latestLocation: CLLocation?
    private(set) var latestSpeed: Measurement<UnitSpeed>?
    var latestCoordinate: CLLocationCoordinate2D? { latestLocation?.coordinate }

    private var isSimulating: Bool = false
    private var simulationTimer: Timer?
    private var simulatedSpeed: Double = 0

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .automotiveNavigation
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = true
        authSubject.send(manager.authorizationStatus)
    }

    var speedPublisher: AnyPublisher<SpeedReading, Never> { subject.eraseToAnyPublisher() }
    var coordinatePublisher: AnyPublisher<CLLocationCoordinate2D?, Never> { coordinateSubject.eraseToAnyPublisher() }
    var authorizationPublisher: AnyPublisher<CLAuthorizationStatus, Never> { authSubject.eraseToAnyPublisher() }
    var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        authSubject.send(manager.authorizationStatus)
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
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
            simulatedSpeed += 2 // ramp
            if simulatedSpeed > 90 { simulatedSpeed = 0 }
            let reading = SpeedReading.simulated(at: simulatedSpeed)
            latestSpeed = reading.speed
            subject.send(reading)
        }
        #endif
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authSubject.send(manager.authorizationStatus)
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        } else {
            startSimulationIfNeeded()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        latestLocation = location
        coordinateSubject.send(latestCoordinate)
        if location.speed >= 0 { // -1 means invalid
            var speedMps = location.speed
            if speedMps < 0 { speedMps = 0 }
            // Deadband: clamp tiny noise under ~1.0 km/h to 0
            let rawKmh = speedMps * 3.6
            let speedKmh = rawKmh < 1.0 ? 0.0 : rawKmh
            let reading = SpeedReading(speed: Measurement(value: speedKmh, unit: .kilometersPerHour), timestamp: Date(), horizontalAccuracy: location.horizontalAccuracy)
            latestSpeed = reading.speed
            subject.send(reading)
        }
        adaptAccuracyPolicy(with: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // For MVP, fall back to simulation on failure
        startSimulationIfNeeded()
    }

    private func adaptAccuracyPolicy(with location: CLLocation) {
        // Basic adaptive policy: relax when slow/stationary
        let speedKmh = max(0, location.speed) * 3.6
        if speedKmh < 3 {
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = 2 // meters
        } else if speedKmh > 110 {
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            manager.distanceFilter = 15 // meters
        } else {
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            manager.distanceFilter = 5 // meters
        }
    }
}
