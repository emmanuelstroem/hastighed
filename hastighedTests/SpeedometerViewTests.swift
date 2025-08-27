import XCTest
@testable import hastighed

final class SpeedometerViewTests: XCTestCase {
    func testSeverityWithinLimit() {
        let s = SpeedometerView.determineSeverity(speedKmh: 50, limitKmh: 50, units: .kmh)
        XCTAssertEqual(s, .within)
    }
    
    func testSeverityWithinBuffer() {
        let s = SpeedometerView.determineSeverity(speedKmh: 52.4, limitKmh: 50, units: .kmh)
        XCTAssertEqual(s, .buffer)
    }
    
    func testSeverityOverThreshold() {
        let s = SpeedometerView.determineSeverity(speedKmh: 60, limitKmh: 50, units: .kmh)
        XCTAssertEqual(s, .over)
    }
    
    func testSeverityRespectsUnits() {
        // 60 mph ~ 96.56 km/h, limit 60 mph -> within
        let s1 = SpeedometerView.determineSeverity(speedKmh: 96.56, limitKmh: 96.56, units: .mph)
        XCTAssertEqual(s1, .within)
        // 62 mph (~99.78 km/h) against 60 mph -> buffer
        let s2 = SpeedometerView.determineSeverity(speedKmh: 99.78, limitKmh: 96.56, units: .mph)
        XCTAssertEqual(s2, .buffer)
    }
}


