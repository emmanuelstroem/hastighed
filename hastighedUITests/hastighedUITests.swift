import XCTest

final class hastighedUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-uiTests")
    }

    func testVisibilityTogglesPersist() {
        app.launch()

        // Open Settings
        app.buttons["settingsButton"].firstMatch.tap()

        // Toggle gauge off
        let gaugeToggle = app.switches["toggle.showGauge"].firstMatch
        if gaugeToggle.exists { gaugeToggle.tap() }

        // Toggle speed limit off
        let speedLimitToggle = app.switches["toggle.showSpeedLimit"].firstMatch
        if speedLimitToggle.exists { speedLimitToggle.tap() }

        // Toggle debug overlay on
        let debugToggle = app.switches["toggle.debugOverlay"].firstMatch
        if debugToggle.exists {
            // Ensure ON
            if debugToggle.value as? String == "0" { debugToggle.tap() }
        }

        // Dismiss settings
        app.buttons["Done"].firstMatch.tap()

        // Verify gauge and speed limit are hidden, debug overlay visible
        XCTAssertFalse(app.otherElements["gauge"].firstMatch.exists)
        XCTAssertFalse(app.otherElements["speedLimitSign"].firstMatch.exists)
        XCTAssertTrue(app.otherElements["debugOverlay"].firstMatch.exists)

        // Relaunch to verify persistence
        app.terminate()
        app.launch()

        XCTAssertFalse(app.otherElements["gauge"].firstMatch.exists)
        XCTAssertFalse(app.otherElements["speedLimitSign"].firstMatch.exists)
        XCTAssertTrue(app.otherElements["debugOverlay"].firstMatch.exists)
    }
}


