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

    // Config
    let lookAheadMeters: Double = 250
    @Published var tolerance: Double = 3

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
        locationService.start()
    }

    private func bind() {
        locationService.speedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reading in
                guard let self else { return }
                speedReading = reading
                let limit = speedLimitService.currentSpeedLimit(for: locationService.latestLocation)
                speedLimit = limit
                refreshContext()
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
}

extension HomeViewModel {
    static func preview() -> HomeViewModel {
        class MockLocation: LocationServicing {
            var latestSpeed: Measurement<UnitSpeed>? = Measurement(value: 0, unit: .kilometersPerHour)
            var latestLocation: CLLocation? = CLLocation(latitude: 0, longitude: 0)
            let subject = PassthroughSubject<SpeedReading, Never>()
            var speedPublisher: AnyPublisher<SpeedReading, Never> { subject.eraseToAnyPublisher() }
            func start() {
                for i in 0..<5 { // simulate increasing speeds
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
                        self.subject.send(.simulated(at: Double(i) * 10))
                    }
                }
            }
            func stop() {}
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
