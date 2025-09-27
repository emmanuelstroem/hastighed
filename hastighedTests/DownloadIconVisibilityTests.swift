import XCTest
@testable import hastighed

final class DownloadIconVisibilityTests: XCTestCase {
    
    var downloadService: DownloadService!
    
    override func setUp() {
        super.setUp()
        downloadService = DownloadService.shared
    }
    
    override func tearDown() {
        downloadService = nil
        super.tearDown()
    }
    
    // MARK: - Icon Visibility Logic Tests
    
    func testDownloadIconShowsWhenNoDownloadExists() {
        // Given: A dataset with no download status
        let datasetIdentifier = "test-dataset"
        
        // When: Checking icon visibility
        let shouldShowDownload = shouldShowDownloadIcon(for: datasetIdentifier)
        let shouldShowPause = shouldShowPauseIcon(for: datasetIdentifier)
        let shouldShowDelete = shouldShowDeleteIcon(for: datasetIdentifier)
        
        // Then: Only download icon should be visible
        XCTAssertTrue(shouldShowDownload, "Download icon should show when no download exists")
        XCTAssertFalse(shouldShowPause, "Pause icon should not show when no download exists")
        XCTAssertFalse(shouldShowDelete, "Delete icon should not show when no download exists")
    }
    
    func testDownloadIconShowsWhenResumingFromPaused() {
        // Given: A paused download
        let datasetIdentifier = "test-dataset"
        let pausedItem = DownloadItem(
            datasetIdentifier: datasetIdentifier,
            downloadStatus: .paused,
            downloadedByteCount: 500,
            totalByteCount: 1000,
            lastUpdatedAt: .now
        )
        
        // When: Checking icon visibility
        let shouldShowDownload = shouldShowDownloadIcon(for: datasetIdentifier, item: pausedItem)
        let shouldShowPause = shouldShowPauseIcon(for: datasetIdentifier, item: pausedItem)
        let shouldShowDelete = shouldShowDeleteIcon(for: datasetIdentifier, item: pausedItem)
        
        // Then: Only download icon should be visible (for resume)
        XCTAssertTrue(shouldShowDownload, "Download icon should show when resuming from paused")
        XCTAssertFalse(shouldShowPause, "Pause icon should not show when paused")
        XCTAssertFalse(shouldShowDelete, "Delete icon should not show when paused")
    }
    
    func testPauseIconShowsWhenDownloading() {
        // Given: An active download
        let datasetIdentifier = "test-dataset"
        let downloadingItem = DownloadItem(
            datasetIdentifier: datasetIdentifier,
            downloadStatus: .downloading,
            downloadedByteCount: 500,
            totalByteCount: 1000,
            lastUpdatedAt: .now
        )
        
        // When: Checking icon visibility
        let shouldShowDownload = shouldShowDownloadIcon(for: datasetIdentifier, item: downloadingItem)
        let shouldShowPause = shouldShowPauseIcon(for: datasetIdentifier, item: downloadingItem)
        let shouldShowDelete = shouldShowDeleteIcon(for: datasetIdentifier, item: downloadingItem)
        
        // Then: Only pause icon should be visible
        XCTAssertFalse(shouldShowDownload, "Download icon should not show when downloading")
        XCTAssertTrue(shouldShowPause, "Pause icon should show when downloading")
        XCTAssertFalse(shouldShowDelete, "Delete icon should not show when downloading")
    }
    
    func testDeleteIconShowsOnlyWhenFullyDownloadedAndAvailable() {
        // Given: A completed download with local file
        let datasetIdentifier = "test-dataset"
        let completedItem = DownloadItem(
            datasetIdentifier: datasetIdentifier,
            downloadStatus: .completed,
            downloadedByteCount: 1000,
            totalByteCount: 1000,
            lastUpdatedAt: .now
        )
        
        // Mock local file exists
        // Note: In real implementation, this would be mocked or the file would actually exist
        
        // When: Checking icon visibility
        let shouldShowDownload = shouldShowDownloadIcon(for: datasetIdentifier, item: completedItem)
        let shouldShowPause = shouldShowPauseIcon(for: datasetIdentifier, item: completedItem)
        let shouldShowDelete = shouldShowDeleteIcon(for: datasetIdentifier, item: completedItem, localFileExists: true)
        
        // Then: Only delete icon should be visible
        XCTAssertFalse(shouldShowDownload, "Download icon should not show when completed")
        XCTAssertFalse(shouldShowPause, "Pause icon should not show when completed")
        XCTAssertTrue(shouldShowDelete, "Delete icon should show when fully downloaded and available")
    }
    
    func testDeleteIconNotShownWhenCompletedButNoLocalFile() {
        // Given: A completed download but no local file
        let datasetIdentifier = "test-dataset"
        let completedItem = DownloadItem(
            datasetIdentifier: datasetIdentifier,
            downloadStatus: .completed,
            downloadedByteCount: 1000,
            totalByteCount: 1000,
            lastUpdatedAt: .now
        )
        
        // When: Checking icon visibility
        let shouldShowDownload = shouldShowDownloadIcon(for: datasetIdentifier, item: completedItem)
        let shouldShowPause = shouldShowPauseIcon(for: datasetIdentifier, item: completedItem)
        let shouldShowDelete = shouldShowDeleteIcon(for: datasetIdentifier, item: completedItem, localFileExists: false)
        
        // Then: Download icon should show (to re-download), delete should not
        XCTAssertTrue(shouldShowDownload, "Download icon should show when completed but no local file")
        XCTAssertFalse(shouldShowPause, "Pause icon should not show when completed")
        XCTAssertFalse(shouldShowDelete, "Delete icon should not show when no local file exists")
    }
    
    func testQueuedStateShowsDownloadIcon() {
        // Given: A queued download
        let datasetIdentifier = "test-dataset"
        let queuedItem = DownloadItem(
            datasetIdentifier: datasetIdentifier,
            downloadStatus: .queued,
            downloadedByteCount: 0,
            totalByteCount: 1000,
            lastUpdatedAt: .now
        )
        
        // When: Checking icon visibility
        let shouldShowDownload = shouldShowDownloadIcon(for: datasetIdentifier, item: queuedItem)
        let shouldShowPause = shouldShowPauseIcon(for: datasetIdentifier, item: queuedItem)
        let shouldShowDelete = shouldShowDeleteIcon(for: datasetIdentifier, item: queuedItem)
        
        // Then: Only download icon should be visible
        XCTAssertTrue(shouldShowDownload, "Download icon should show when queued")
        XCTAssertFalse(shouldShowPause, "Pause icon should not show when queued")
        XCTAssertFalse(shouldShowDelete, "Delete icon should not show when queued")
    }
    
    func testFailedStateShowsDownloadIcon() {
        // Given: A failed download
        let datasetIdentifier = "test-dataset"
        let failedItem = DownloadItem(
            datasetIdentifier: datasetIdentifier,
            downloadStatus: .failed,
            downloadedByteCount: 500,
            totalByteCount: 1000,
            lastUpdatedAt: .now,
            lastErrorDescription: "Network error"
        )
        
        // When: Checking icon visibility
        let shouldShowDownload = shouldShowDownloadIcon(for: datasetIdentifier, item: failedItem)
        let shouldShowPause = shouldShowPauseIcon(for: datasetIdentifier, item: failedItem)
        let shouldShowDelete = shouldShowDeleteIcon(for: datasetIdentifier, item: failedItem)
        
        // Then: Only download icon should be visible (to retry)
        XCTAssertTrue(shouldShowDownload, "Download icon should show when failed")
        XCTAssertFalse(shouldShowPause, "Pause icon should not show when failed")
        XCTAssertFalse(shouldShowDelete, "Delete icon should not show when failed")
    }
    
    func testCanceledStateShowsDownloadIcon() {
        // Given: A canceled download
        let datasetIdentifier = "test-dataset"
        let canceledItem = DownloadItem(
            datasetIdentifier: datasetIdentifier,
            downloadStatus: .canceled,
            downloadedByteCount: 0,
            totalByteCount: 1000,
            lastUpdatedAt: .now
        )
        
        // When: Checking icon visibility
        let shouldShowDownload = shouldShowDownloadIcon(for: datasetIdentifier, item: canceledItem)
        let shouldShowPause = shouldShowPauseIcon(for: datasetIdentifier, item: canceledItem)
        let shouldShowDelete = shouldShowDeleteIcon(for: datasetIdentifier, item: canceledItem)
        
        // Then: Only download icon should be visible (to restart)
        XCTAssertTrue(shouldShowDownload, "Download icon should show when canceled")
        XCTAssertFalse(shouldShowPause, "Pause icon should not show when canceled")
        XCTAssertFalse(shouldShowDelete, "Delete icon should not show when canceled")
    }
    
    // MARK: - Helper Methods
    
    private func shouldShowDownloadIcon(for datasetIdentifier: String, item: DownloadItem? = nil) -> Bool {
        let status = item ?? downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        guard let status = status else { return true } // No status = show download
        
        switch status.downloadStatus {
        case .queued, .paused, .failed, .canceled:
            return true
        case .downloading, .completed:
            return false
        }
    }
    
    private func shouldShowPauseIcon(for datasetIdentifier: String, item: DownloadItem? = nil) -> Bool {
        let status = item ?? downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        guard let status = status else { return false }
        
        return status.downloadStatus == .downloading
    }
    
    private func shouldShowDeleteIcon(for datasetIdentifier: String, item: DownloadItem? = nil, localFileExists: Bool = false) -> Bool {
        let status = item ?? downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        guard let status = status else { return false }
        
        return status.downloadStatus == .completed && localFileExists
    }
}
