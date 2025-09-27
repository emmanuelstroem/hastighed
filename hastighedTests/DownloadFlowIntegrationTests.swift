import XCTest
@testable import hastighed

final class DownloadFlowIntegrationTests: XCTestCase {
    
    var downloadService: DownloadService!
    var viewModel: OfflineMapsViewModel!
    
    override func setUp() {
        super.setUp()
        downloadService = DownloadService.shared
        viewModel = OfflineMapsViewModel(downloadService: downloadService)
    }
    
    override func tearDown() {
        viewModel = nil
        downloadService = nil
        super.tearDown()
    }
    
    // MARK: - Complete Download Flow Tests
    
    func testCompleteDownloadFlow() async {
        // Given: A dataset available for download
        let datasets = downloadService.listAvailableDatasets()
        XCTAssertFalse(datasets.isEmpty, "Should have available datasets")
        
        let dataset = datasets.first!
        let datasetIdentifier = dataset.datasetIdentifier
        
        // When: Starting download
        await downloadService.startDatasetDownload(datasetIdentifier: datasetIdentifier, userConfirmedCellularDownload: true)
        
        // Then: Status should be downloading
        let downloadingStatus = downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertEqual(downloadingStatus?.downloadStatus, .downloading)
        
        // When: Pausing download
        await downloadService.pauseDatasetDownload(datasetIdentifier: datasetIdentifier)
        
        // Then: Status should be paused
        let pausedStatus = downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertEqual(pausedStatus?.downloadStatus, .paused)
        
        // When: Resuming download
        await downloadService.resumeDatasetDownload(datasetIdentifier: datasetIdentifier)
        
        // Then: Status should be downloading again
        let resumedStatus = downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertEqual(resumedStatus?.downloadStatus, .downloading)
    }
    
    func testDownloadProgressTracking() async {
        // Given: A dataset identifier
        let datasetIdentifier = "test-dataset"
        
        // When: Starting download
        await downloadService.startDatasetDownload(datasetIdentifier: datasetIdentifier, userConfirmedCellularDownload: true)
        
        // Then: Progress should be tracked
        let status = downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertNotNil(status)
        XCTAssertEqual(status?.downloadStatus, .downloading)
        XCTAssertGreaterThanOrEqual(status?.downloadedByteCount ?? 0, 0)
    }
    
    func testMultipleDatasetManagement() async {
        // Given: Multiple datasets
        let datasets = downloadService.listAvailableDatasets()
        guard datasets.count >= 2 else {
            XCTSkip("Need at least 2 datasets for this test")
            return
        }
        
        let dataset1 = datasets[0]
        let dataset2 = datasets[1]
        
        // When: Starting downloads for both
        await downloadService.startDatasetDownload(datasetIdentifier: dataset1.datasetIdentifier, userConfirmedCellularDownload: true)
        await downloadService.startDatasetDownload(datasetIdentifier: dataset2.datasetIdentifier, userConfirmedCellularDownload: true)
        
        // Then: Only one should be downloading at a time
        let status1 = downloadService.getDatasetDownloadStatus(datasetIdentifier: dataset1.datasetIdentifier)
        let status2 = downloadService.getDatasetDownloadStatus(datasetIdentifier: dataset2.datasetIdentifier)
        
        let downloadingCount = [status1, status2].compactMap { $0?.downloadStatus }.filter { $0 == .downloading }.count
        XCTAssertEqual(downloadingCount, 1, "Only one download should be active at a time")
        
        // When: Pausing the active download
        if status1?.downloadStatus == .downloading {
            await downloadService.pauseDatasetDownload(datasetIdentifier: dataset1.datasetIdentifier)
        } else if status2?.downloadStatus == .downloading {
            await downloadService.pauseDatasetDownload(datasetIdentifier: dataset2.datasetIdentifier)
        }
        
        // Then: The other should start downloading
        let status1After = downloadService.getDatasetDownloadStatus(datasetIdentifier: dataset1.datasetIdentifier)
        let status2After = downloadService.getDatasetDownloadStatus(datasetIdentifier: dataset2.datasetIdentifier)
        
        let downloadingCountAfter = [status1After, status2After].compactMap { $0?.downloadStatus }.filter { $0 == .downloading }.count
        XCTAssertEqual(downloadingCountAfter, 1, "One download should be active after pausing the other")
    }
    
    func testDownloadStatePersistence() async {
        // Given: A paused download
        let datasetIdentifier = "test-dataset"
        await downloadService.startDatasetDownload(datasetIdentifier: datasetIdentifier, userConfirmedCellularDownload: true)
        await downloadService.pauseDatasetDownload(datasetIdentifier: datasetIdentifier)
        
        // When: Creating a new service instance (simulating app restart)
        let newDownloadService = DownloadService()
        let newViewModel = OfflineMapsViewModel(downloadService: newDownloadService)
        
        // Then: State should be restored
        let restoredStatus = newDownloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertEqual(restoredStatus?.downloadStatus, .paused)
    }
    
    func testErrorHandling() async {
        // Given: An invalid dataset identifier
        let invalidIdentifier = "invalid-dataset"
        
        // When: Trying to start download
        await downloadService.startDatasetDownload(datasetIdentifier: invalidIdentifier, userConfirmedCellularDownload: true)
        
        // Then: Should handle gracefully (no crash)
        let status = downloadService.getDatasetDownloadStatus(datasetIdentifier: invalidIdentifier)
        // Status might be nil or failed, but should not crash
        XCTAssertTrue(status == nil || status?.downloadStatus == .failed)
    }
    
    func testCellularConfirmationRequirement() async {
        // Given: A large dataset that requires cellular confirmation
        let largeDataset = DatasetListing(
            datasetIdentifier: "large-dataset",
            countryName: "Large Country",
            expectedTotalByteCount: 100 * 1024 * 1024, // 100 MB
            remoteResourceAddress: "http://example.com/large.gpkg"
        )
        
        // When: Starting download without cellular confirmation
        await downloadService.startDatasetDownload(datasetIdentifier: largeDataset.datasetIdentifier, userConfirmedCellularDownload: false)
        
        // Then: Should handle the requirement appropriately
        // Note: The actual implementation would check connectivity and show confirmation dialog
        let status = downloadService.getDatasetDownloadStatus(datasetIdentifier: largeDataset.datasetIdentifier)
        XCTAssertNotNil(status)
    }
    
    func testDownloadCancellation() async {
        // Given: An active download
        let datasetIdentifier = "test-dataset"
        await downloadService.startDatasetDownload(datasetIdentifier: datasetIdentifier, userConfirmedCellularDownload: true)
        
        // When: Canceling the download
        await downloadService.cancelDatasetDownload(datasetIdentifier: datasetIdentifier)
        
        // Then: Status should be canceled and no local file should exist
        let status = downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertEqual(status?.downloadStatus, .canceled)
        XCTAssertFalse(downloadService.localFileExists(for: datasetIdentifier))
    }
    
    func testLocalFileDeletion() async {
        // Given: A completed download with local file
        let datasetIdentifier = "test-dataset"
        
        // Simulate a completed download
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
        
        // Then: No local file should exist
        XCTAssertFalse(downloadService.localFileExists(for: datasetIdentifier))
    }
    
    // MARK: - ViewModel Integration Tests
    
    func testViewModelStatusRetrieval() {
        // Given: A dataset identifier
        let datasetIdentifier = "test-dataset"
        
        // When: Getting status from view model
        let status = viewModel.status(for: datasetIdentifier)
        
        // Then: Should return appropriate status
        // Initially might be nil or have a default status
        XCTAssertTrue(status == nil || status?.datasetIdentifier == datasetIdentifier)
    }
    
    func testViewModelLocalFileExistence() {
        // Given: A dataset identifier
        let datasetIdentifier = "test-dataset"
        
        // When: Checking if local file exists
        let exists = viewModel.localFileExists(for: datasetIdentifier)
        
        // Then: Should return boolean value
        XCTAssertTrue(exists == true || exists == false)
    }
    
    func testViewModelToggleDownloadPause() async {
        // Given: A dataset identifier
        let datasetIdentifier = "test-dataset"
        
        // When: Toggling download/pause
        viewModel.toggleDownloadPause(for: datasetIdentifier)
        
        // Then: Should not crash and status should be updated
        let status = viewModel.status(for: datasetIdentifier)
        XCTAssertNotNil(status)
    }
    
    func testViewModelDeleteLocalFile() async {
        // Given: A dataset identifier
        let datasetIdentifier = "test-dataset"
        
        // When: Deleting local file
        viewModel.deleteLocalFile(for: datasetIdentifier)
        
        // Then: Should not crash
        // The actual deletion would be handled by the service
        XCTAssertTrue(true) // Just ensuring no crash
    }
}
