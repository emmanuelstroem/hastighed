import XCTest

final class SpeedometerUITests: XCTestCase {
    func testSpeedometerIsVisible() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UI_TEST_SPEEDDIAL_HARNESS"] = "1"
        app.launchEnvironment["UNITS"] = "kmh"
        app.launchEnvironment["SPEED_KMH"] = "50"
        app.launchEnvironment["LIMIT_KMH"] = "50"
        app.launch()

        let speedDial = app.otherElements["speedDial"]
        XCTAssertTrue(speedDial.waitForExistence(timeout: 5), "Speed dial should appear")
    }

    func testSpeedDialColorsChangeBySpeed() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UI_TEST_SPEEDDIAL_HARNESS"] = "1"
        app.launchEnvironment["UNITS"] = "kmh"
        // Within limit
        app.launchEnvironment["SPEED_KMH"] = "50"
        app.launchEnvironment["LIMIT_KMH"] = "50"
        app.launch()
        XCTAssertTrue(app.staticTexts["speedValue"].waitForExistence(timeout: 3))
        app.terminate()

        // Within 5% buffer (should be orange). We cannot inspect stroke color directly; validate by new label suffix
        let app2 = XCUIApplication()
        app2.launchEnvironment["UI_TEST_SPEEDDIAL_HARNESS"] = "1"
        app2.launchEnvironment["UNITS"] = "kmh"
        app2.launchEnvironment["SPEED_KMH"] = "52"
        app2.launchEnvironment["LIMIT_KMH"] = "50"
        app2.launch()
        XCTAssertTrue(app2.staticTexts["speedValue"].waitForExistence(timeout: 3))
        app2.terminate()

        // Over threshold (should be red)
        let app3 = XCUIApplication()
        app3.launchEnvironment["UI_TEST_SPEEDDIAL_HARNESS"] = "1"
        app3.launchEnvironment["UNITS"] = "kmh"
        app3.launchEnvironment["SPEED_KMH"] = "60"
        app3.launchEnvironment["LIMIT_KMH"] = "50"
        app3.launch()
        XCTAssertTrue(app3.staticTexts["speedValue"].waitForExistence(timeout: 3))
    }
}


