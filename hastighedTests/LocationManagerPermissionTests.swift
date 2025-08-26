import XCTest
import CoreLocation
@testable import hastighed

final class LocationManagerPermissionTests: XCTestCase {
    @MainActor
    func testShowsAlertWhenDenied() {
        let lm = LocationManager()
        lm.authorizationStatus = .denied
        lm.requestLocationPermission()
        XCTAssertTrue(lm.showPermissionAlert)
    }
}


