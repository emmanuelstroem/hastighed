import Foundation
import Combine
import CoreLocation

@MainActor
final class HomeViewModel: ObservableObject {
    // Inputs
    private let locationService: LocationServicing
    private let speedLimitService: SpeedLimitProviding
    private let upcomingProvider: UpcomingLimitProviding
    private let cameraProvider: SpeedCameraProviding
    private let hazardProvider: RoadHazardProviding

    // Published
    @Published private(set) var speedReading: SpeedReading?
    @Published private(set) var speedLimit: SpeedLimit = SpeedLimit(kmh: 50, source: .ruleFallback, confidence: 0.2)
    @Published private(set) var upcomingLimitChanges: [UpcomingSpeedLimitChange] = []
    @Published private(set) var speedCameras: [SpeedCamera] = []
    @Published private(set) var roadHazards: [RoadHazard] = []
    @Published private(set) var locationAccuracy: CLLocationAccuracy?
    @Published private(set) var debugSnapshot: DebugSnapshot = DebugSnapshot(speed: nil, coordinate: nil, speedLimit: nil, unitLabel: AppConstants.speedUnitLabel)
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var shouldShowPermissionOverlay: Bool = false

    // Config
    let lookAheadMeters: Double = 250
    @Published var tolerance: Double = 0 // kilometers

    private var cancellables = Set<AnyCancellable>()

    init(locationService: LocationServicing,
         speedLimitService: SpeedLimitProviding,
         upcomingProvider: UpcomingLimitProviding,
         cameraProvider: SpeedCameraProviding,
         hazardProvider: RoadHazardProviding) {
        self.locationService = locationService
        self.speedLimitService = speedLimitService
        self.upcomingProvider = upcomingProvider
        self.cameraProvider = cameraProvider
        self.hazardProvider = hazardProvider
        bind()
        updateDebugSnapshot()
        locationService.start()
    }

    private func bind() {
        locationService.speedPublisher
            .removeDuplicates(by: { [weak self] lhs, rhs in
                let dl = lhs.speed.converted(to: .kilometersPerHour).value
                let dr = rhs.speed.converted(to: .kilometersPerHour).value
                let tol = self?.tolerance ?? 0.1
                return abs(dl - dr) < tol
            })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reading in
                guard let self else { return }
                speedReading = reading
                let limit = speedLimitService.currentSpeedLimit(for: locationService.latestLocation)
                speedLimit = limit
                refreshContext()
                updateDebugSnapshot()
            }
            .store(in: &cancellables)

        locationService.authorizationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                authorizationStatus = status
                shouldShowPermissionOverlay = (status == .denied || status == .restricted)
            }
            .store(in: &cancellables)

        locationService.coordinatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDebugSnapshot()
            }
            .store(in: &cancellables)
    }

    private func refreshContext() {
        guard let loc = locationService.latestLocation else { return }
        locationAccuracy = loc.horizontalAccuracy
        upcomingLimitChanges = upcomingProvider.upcomingChanges(within: lookAheadMeters, from: loc)
        speedCameras = cameraProvider.nearbyCameras(within: lookAheadMeters, from: loc)
        roadHazards = hazardProvider.nearbyHazards(within: lookAheadMeters, from: loc)
    }

    private func updateDebugSnapshot() {
        let coord = locationService.latestCoordinate
        debugSnapshot = DebugSnapshot(
            speed: speedReading?.speed,
            coordinate: coord,
            speedLimit: speedLimit,
            unitLabel: settingsUnitLabel()
        )
    }

    private func settingsUnitLabel() -> String {
        return AppConstants.speedUnitLabel
    }

    func requestPermissionIfNeeded() {
        if authorizationStatus == .notDetermined {
            locationService.requestAuthorization()
        }
    }

    func openSettings() {
        locationService.openAppSettings()
    }

    // battery saver removed
}

extension HomeViewModel {
    static func preview() -> HomeViewModel {
        class MockLocation: LocationServicing {
            var latestSpeed: Measurement<UnitSpeed>? = Measurement(value: 0, unit: .kilometersPerHour)
            var latestLocation: CLLocation? = CLLocation(latitude: 0, longitude: 0)
            var latestCoordinate: CLLocationCoordinate2D? { latestLocation?.coordinate }
            let subject = PassthroughSubject<SpeedReading, Never>()
            var speedPublisher: AnyPublisher<SpeedReading, Never> { subject.eraseToAnyPublisher() }
            var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
            private let auth = CurrentValueSubject<CLAuthorizationStatus, Never>(.authorizedWhenInUse)
            var authorizationPublisher: AnyPublisher<CLAuthorizationStatus, Never> { auth.eraseToAnyPublisher() }
            private let coord = CurrentValueSubject<CLLocationCoordinate2D?, Never>(CLLocationCoordinate2D(latitude: 0, longitude: 0))
            var coordinatePublisher: AnyPublisher<CLLocationCoordinate2D?, Never> { coord.eraseToAnyPublisher() }
            func start() {
                for i in 0..<5 { // simulate increasing speeds
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
                        self.subject.send(.simulated(at: Double(i) * 10))
                    }
                }
            }
            func stop() {}
            func requestAuthorization() { /* no-op in preview */ }
            func openAppSettings() { /* no-op in preview */ }
        }
        return HomeViewModel(
            locationService: MockLocation(),
            speedLimitService: SpeedLimitService(),
            upcomingProvider: MockUpcomingLimitProvider(),
            cameraProvider: MockSpeedCameraProvider(),
            hazardProvider: MockRoadHazardProvider()
        )
    }
}
