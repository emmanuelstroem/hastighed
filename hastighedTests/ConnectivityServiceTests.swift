import XCTest
@testable import hastighed

final class ConnectivityServiceTests: XCTestCase {
    func testImmediateCallbackReceivesCurrentStatus() {
        let svc = ConnectivityService.shared
        let exp = expectation(description: "Immediate callback")
        var received: ConnectivityStatus?

        svc.updateForMock(usable: true, networkType: .wifi)
        svc.onStatusChange { status in
            received = status
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(received?.usable, true)
        XCTAssertEqual(received?.networkType, .wifi)
    }

    func testNetworkTypeMapping() {
        let svc = ConnectivityService.shared
        let exp = expectation(description: "Mapping")

        svc.updateForMock(usable: false, networkType: .none)
        svc.onStatusChange { status in
            XCTAssertEqual(status.usable, false)
            XCTAssertEqual(status.networkType, .none)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }
}


