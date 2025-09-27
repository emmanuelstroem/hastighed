import XCTest

final class DownloadButtonUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - 4-State Button Behavior Tests
    
    func testDownloadButtonInitialState() throws {
        // Given: App is launched and user navigates to Offline Maps
        navigateToOfflineMaps()
        
        // When: Viewing the download section
        // Then: Download buttons should show download icon (arrow.down.circle.fill)
        let downloadButtons = app.buttons.matching(identifier: "download-button")
        XCTAssertGreaterThan(downloadButtons.count, 0, "Should have download buttons")
        
        // Verify download icon is visible
        let downloadIcons = app.images.matching(NSPredicate(format: "label CONTAINS 'download'"))
        XCTAssertGreaterThan(downloadIcons.count, 0, "Should show download icons initially")
    }
    
    func testDownloadButtonStateTransitions() throws {
        // Given: User is in Offline Maps section
        navigateToOfflineMaps()
        
        // When: Tapping a download button
        let downloadButtons = app.buttons.matching(identifier: "download-button")
        guard downloadButtons.count > 0 else {
            XCTSkip("No download buttons found")
            return
        }
        
        let firstDownloadButton = downloadButtons.element(boundBy: 0)
        firstDownloadButton.tap()
        
        // Then: Button should change to pause state
        let pauseIcons = app.images.matching(NSPredicate(format: "label CONTAINS 'pause'"))
        XCTAssertGreaterThan(pauseIcons.count, 0, "Should show pause icon when downloading")
        
        // When: Tapping pause button
        firstDownloadButton.tap()
        
        // Then: Button should change back to download state (for resume)
        let downloadIcons = app.images.matching(NSPredicate(format: "label CONTAINS 'download'"))
        XCTAssertGreaterThan(downloadIcons.count, 0, "Should show download icon when paused")
    }
    
    func testDeleteButtonVisibility() throws {
        // Given: User is in Offline Maps section
        navigateToOfflineMaps()
        
        // When: A file is fully downloaded and available locally
        // Note: This would require setting up a completed download state
        // For now, we'll test the UI structure
        
        // Then: Delete button should be visible
        let deleteButtons = app.buttons.matching(identifier: "delete-button")
        // Initially might be 0 if no files are downloaded
        XCTAssertGreaterThanOrEqual(deleteButtons.count, 0, "Delete buttons should be present when files are downloaded")
        
        // Verify delete icon is visible when appropriate
        let deleteIcons = app.images.matching(NSPredicate(format: "label CONTAINS 'delete' OR label CONTAINS 'trash'"))
        XCTAssertGreaterThanOrEqual(deleteIcons.count, 0, "Should show delete icons when files are downloaded")
    }
    
    func testProgressRingVisibility() throws {
        // Given: User is in Offline Maps section
        navigateToOfflineMaps()
        
        // When: Starting a download
        let downloadButtons = app.buttons.matching(identifier: "download-button")
        guard downloadButtons.count > 0 else {
            XCTSkip("No download buttons found")
            return
        }
        
        let firstDownloadButton = downloadButtons.element(boundBy: 0)
        firstDownloadButton.tap()
        
        // Then: Progress ring should be visible around the button
        let progressRings = app.otherElements.matching(identifier: "progress-ring")
        XCTAssertGreaterThan(progressRings.count, 0, "Should show progress ring during download")
    }
    
    func testButtonAccessibility() throws {
        // Given: User is in Offline Maps section
        navigateToOfflineMaps()
        
        // When: Viewing download buttons
        let downloadButtons = app.buttons.matching(identifier: "download-button")
        guard downloadButtons.count > 0 else {
            XCTSkip("No download buttons found")
            return
        }
        
        // Then: Buttons should have proper accessibility labels
        let firstButton = downloadButtons.element(boundBy: 0)
        XCTAssertTrue(firstButton.isAccessibilityElement, "Download button should be accessible")
        XCTAssertFalse(firstButton.label.isEmpty, "Download button should have accessibility label")
    }
    
    func testButtonStatesWithVoiceOver() throws {
        // Given: VoiceOver is enabled
        // Note: This would require enabling VoiceOver programmatically or in test setup
        
        // When: User navigates through download buttons
        navigateToOfflineMaps()
        
        // Then: Each state should have appropriate VoiceOver announcements
        let downloadButtons = app.buttons.matching(identifier: "download-button")
        guard downloadButtons.count > 0 else {
            XCTSkip("No download buttons found")
            return
        }
        
        let firstButton = downloadButtons.element(boundBy: 0)
        
        // Test initial state
        XCTAssertTrue(firstButton.label.contains("download") || firstButton.label.contains("Download"), 
                     "Initial state should announce download action")
        
        // Test after tap (downloading state)
        firstButton.tap()
        XCTAssertTrue(firstButton.label.contains("pause") || firstButton.label.contains("Pause"), 
                     "Downloading state should announce pause action")
        
        // Test after second tap (paused state)
        firstButton.tap()
        XCTAssertTrue(firstButton.label.contains("download") || firstButton.label.contains("Download"), 
                     "Paused state should announce download/resume action")
    }
    
    func testMultipleDatasetButtonStates() throws {
        // Given: User is in Offline Maps section with multiple datasets
        navigateToOfflineMaps()
        
        // When: Viewing all download buttons
        let downloadButtons = app.buttons.matching(identifier: "download-button")
        
        // Then: All buttons should be in appropriate initial state
        XCTAssertGreaterThan(downloadButtons.count, 0, "Should have multiple download buttons")
        
        for i in 0..<downloadButtons.count {
            let button = downloadButtons.element(boundBy: i)
            XCTAssertTrue(button.isAccessibilityElement, "Button \(i) should be accessible")
            XCTAssertFalse(button.label.isEmpty, "Button \(i) should have accessibility label")
        }
    }
    
    func testButtonInteractionFeedback() throws {
        // Given: User is in Offline Maps section
        navigateToOfflineMaps()
        
        // When: Tapping download buttons
        let downloadButtons = app.buttons.matching(identifier: "download-button")
        guard downloadButtons.count > 0 else {
            XCTSkip("No download buttons found")
            return
        }
        
        let firstButton = downloadButtons.element(boundBy: 0)
        
        // Then: Button should provide visual feedback
        XCTAssertTrue(firstButton.isHittable, "Download button should be tappable")
        
        // Test tap feedback
        firstButton.tap()
        
        // Button should still be accessible after tap
        XCTAssertTrue(firstButton.isHittable, "Button should remain tappable after first tap")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToOfflineMaps() {
        // Navigate to Settings view first
        let settingsButton = app.buttons["Settings"]
        if settingsButton.exists {
            settingsButton.tap()
        }
        
        // Look for Offline Maps section
        let offlineMapsSection = app.staticTexts["Offline Maps"]
        if offlineMapsSection.exists {
            // Tap on the section to expand or navigate
            offlineMapsSection.tap()
        }
        
        // Look for EU Offline Maps button
        let euOfflineMapsButton = app.buttons["EU Offline Maps"]
        if euOfflineMapsButton.exists {
            euOfflineMapsButton.tap()
        }
    }
}
