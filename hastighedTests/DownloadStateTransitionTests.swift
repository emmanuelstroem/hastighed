import XCTest
@testable import hastighed

final class DownloadStateTransitionTests: XCTestCase {
    
    var downloadService: DownloadService!
    
    override func setUp() {
        super.setUp()
        downloadService = DownloadService.shared
    }
    
    override func tearDown() {
        downloadService = nil
        super.tearDown()
    }
    
    // MARK: - State Transition Tests
    
    func testDownloadStateTransitions() async {
        // Given: A dataset identifier
        let datasetIdentifier = "test-dataset"
        
        // When: Starting a download
        await downloadService.startDatasetDownload(datasetIdentifier: datasetIdentifier, userConfirmedCellularDownload: true)
        
        // Then: Status should be downloading
        let downloadingStatus = downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertEqual(downloadingStatus?.downloadStatus, .downloading)
        
        // When: Pausing the download
        await downloadService.pauseDatasetDownload(datasetIdentifier: datasetIdentifier)
        
        // Then: Status should be paused
        let pausedStatus = downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertEqual(pausedStatus?.downloadStatus, .paused)
        
        // When: Resuming the download
        await downloadService.resumeDatasetDownload(datasetIdentifier: datasetIdentifier)
        
        // Then: Status should be downloading again
        let resumedStatus = downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertEqual(resumedStatus?.downloadStatus, .downloading)
    }
    
    func testCancelRemovesPartialFiles() async {
        // Given: A dataset with partial download
        let datasetIdentifier = "test-dataset"
        await downloadService.startDatasetDownload(datasetIdentifier: datasetIdentifier, userConfirmedCellularDownload: true)
        
        // When: Canceling the download
        await downloadService.cancelDatasetDownload(datasetIdentifier: datasetIdentifier)
        
        // Then: Status should be canceled and no local file should exist
        let canceledStatus = downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertEqual(canceledStatus?.downloadStatus, .canceled)
        XCTAssertFalse(downloadService.localFileExists(for: datasetIdentifier))
    }
    
    func testDeleteRemovesCompletedFile() async {
        // Given: A completed download
        let datasetIdentifier = "test-dataset"
        await downloadService.startDatasetDownload(datasetIdentifier: datasetIdentifier, userConfirmedCellularDownload: true)
        
        // Simulate completion by manually setting status
        // Note: In real implementation, this would be set by URLSession delegate
        let completedItem = DownloadItem(
            datasetIdentifier: datasetIdentifier,
            downloadStatus: .completed,
            downloadedByteCount: 1000,
            totalByteCount: 1000,
            lastUpdatedAt: .now
        )
        
        // When: Deleting the local file
        do {
            try await downloadService.deleteLocalDatasetFile(datasetIdentifier: datasetIdentifier)
        } catch {
            XCTFail("Delete should not throw error: \(error)")
        }
        
        // Then: No local file should exist and status should be cleared
        XCTAssertFalse(downloadService.localFileExists(for: datasetIdentifier))
        let statusAfterDelete = downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertNil(statusAfterDelete)
    }
    
    func testOnlyOneActiveDownloadAtATime() async {
        // Given: Two dataset identifiers
        let dataset1 = "test-dataset-1"
        let dataset2 = "test-dataset-2"
        
        // When: Starting two downloads
        await downloadService.startDatasetDownload(datasetIdentifier: dataset1, userConfirmedCellularDownload: true)
        await downloadService.startDatasetDownload(datasetIdentifier: dataset2, userConfirmedCellularDownload: true)
        
        // Then: Only one should be downloading, other should be queued
        let status1 = downloadService.getDatasetDownloadStatus(datasetIdentifier: dataset1)
        let status2 = downloadService.getDatasetDownloadStatus(datasetIdentifier: dataset2)
        
        let downloadingCount = [status1, status2].compactMap { $0?.downloadStatus }.filter { $0 == .downloading }.count
        XCTAssertEqual(downloadingCount, 1, "Only one download should be active at a time")
    }
    
    func testStatePersistenceAcrossAppRestart() async {
        // Given: A paused download
        let datasetIdentifier = "test-dataset"
        await downloadService.startDatasetDownload(datasetIdentifier: datasetIdentifier, userConfirmedCellularDownload: true)
        await downloadService.pauseDatasetDownload(datasetIdentifier: datasetIdentifier)
        
        // When: Creating a new DownloadService instance (simulating app restart)
        let newDownloadService = DownloadService()
        
        // Then: The paused state should be restored
        let restoredStatus = newDownloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertEqual(restoredStatus?.downloadStatus, .paused)
    }
    
    // MARK: - Edge Case Tests
    
    func testInvalidStateTransitions() async {
        // Given: A completed download
        let datasetIdentifier = "test-dataset"
        let completedItem = DownloadItem(
            datasetIdentifier: datasetIdentifier,
            downloadStatus: .completed,
            downloadedByteCount: 1000,
            totalByteCount: 1000,
            lastUpdatedAt: .now
        )
        
        // When: Trying to pause a completed download
        await downloadService.pauseDatasetDownload(datasetIdentifier: datasetIdentifier)
        
        // Then: Status should remain completed
        let status = downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertEqual(status?.downloadStatus, .completed)
    }
    
    func testResumeFromNonPausedState() async {
        // Given: A dataset that was never started
        let datasetIdentifier = "test-dataset"
        
        // When: Trying to resume
        await downloadService.resumeDatasetDownload(datasetIdentifier: datasetIdentifier)
        
        // Then: Should start a new download
        let status = downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertEqual(status?.downloadStatus, .downloading)
    }
}
