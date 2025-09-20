import Foundation
import Combine
import CoreLocation

@MainActor
final class SpeedMonitoringViewModel: ObservableObject {
    // Inputs
    private let locationService: LocationServicing
    private let speedLimitService: SpeedLimitProviding

    // Published state
    @Published private(set) var speedReading: SpeedReading? = nil
    @Published private(set) var speedLimit: SpeedLimit = SpeedLimit(kmh: 50, source: .ruleFallback, confidence: 0.2)
    @Published private(set) var status: LimitStatus = .below(delta: Measurement(value: 50, unit: .kilometersPerHour))

    // Config
    @Published var tolerance: Double = 0.1 // km/h

    private var cancellables = Set<AnyCancellable>()

    init(locationService: LocationServicing, speedLimitService: SpeedLimitProviding) {
        self.locationService = locationService
        self.speedLimitService = speedLimitService
        bind()
        locationService.start()
    }

    private func bind() {
        locationService.speedPublisher
            .removeDuplicates(by: { [weak self] lhs, rhs in
                let settings = SettingsStore()
                let dl = settings.displaySpeed(from: lhs.speed.converted(to: .kilometersPerHour).value)
                let dr = settings.displaySpeed(from: rhs.speed.converted(to: .kilometersPerHour).value)
                let tol = self?.tolerance ?? 0.1
                return abs(dl - dr) < tol
            })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reading in
                guard let self else { return }
                self.speedReading = reading
                let limit = speedLimitService.currentSpeedLimit(for: locationService.latestLocation)
                self.speedLimit = limit
                self.status = self.deriveStatus(speed: reading.speed, limit: limit.value)
            }
            .store(in: &cancellables)
    }

    private func deriveStatus(speed: Measurement<UnitSpeed>, limit: Measurement<UnitSpeed>) -> LimitStatus {
        let deltaValue = speed.converted(to: .kilometersPerHour).value - limit.converted(to: .kilometersPerHour).value
        let delta = Measurement(value: abs(deltaValue), unit: UnitSpeed.kilometersPerHour)
        if deltaValue < -tolerance { // comfortably below
            return .below(delta: delta)
        } else if abs(deltaValue) <= tolerance {
            return .near(delta: delta)
        } else { // over
            return .over(delta: delta)
        }
    }
}

extension SpeedMonitoringViewModel {
    static func preview() -> SpeedMonitoringViewModel {
        class MockLocation: LocationServicing {
            var latestSpeed: Measurement<UnitSpeed>? = Measurement(value: 42, unit: .kilometersPerHour)
            var latestLocation: CLLocation? = nil
            var latestCoordinate: CLLocationCoordinate2D? { latestLocation?.coordinate }
            let subject = PassthroughSubject<SpeedReading, Never>()
            var speedPublisher: AnyPublisher<SpeedReading, Never> { subject.eraseToAnyPublisher() }
            var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
            private let auth = CurrentValueSubject<CLAuthorizationStatus, Never>(.authorizedWhenInUse)
            var authorizationPublisher: AnyPublisher<CLAuthorizationStatus, Never> { auth.eraseToAnyPublisher() }
            private let coord = CurrentValueSubject<CLLocationCoordinate2D?, Never>(CLLocationCoordinate2D(latitude: 0, longitude: 0))
            var coordinatePublisher: AnyPublisher<CLLocationCoordinate2D?, Never> { coord.eraseToAnyPublisher() }
            func start() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.subject.send(.simulated(at: 42))
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.subject.send(.simulated(at: 51))
                }
            }
            func stop() {}
            func requestAuthorization() { /* no-op */ }
            func openAppSettings() { /* no-op */ }
        }
        class MockLimit: SpeedLimitProviding {
            func currentSpeedLimit(for location: CLLocation?) -> SpeedLimit { SpeedLimit(kmh: 50, source: .ruleFallback, confidence: 0.4) }
        }
        return SpeedMonitoringViewModel(locationService: MockLocation(), speedLimitService: MockLimit())
    }
}
