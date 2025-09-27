import XCTest
@testable import hastighed

final class LocalFileCompletionTests: XCTestCase {
    
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
    
    func testLocalFileShowsAsCompleted() async {
        // Given: A dataset identifier
        let datasetIdentifier = "test-local-file"
        
        // Create a mock local file
        let testData = "test data".data(using: .utf8)!
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(datasetIdentifier).gpkg")
        try! testData.write(to: tempURL)
        
        // Mock the storage URL to point to our test file
        // This is a bit tricky since we need to mock the storageURL method
        // For now, let's test the logic directly
        
        // When: Refreshing status for a dataset that has a local file
        // We'll simulate this by directly calling the refreshStatus method
        viewModel.refreshStatus(for: datasetIdentifier)
        
        // Then: The status should be completed
        let status = viewModel.status(for: datasetIdentifier)
        XCTAssertEqual(status?.downloadStatus, .completed, "Local file should show as completed")
    }
    
    func testUpdateDownloadStatusPersists() async {
        // Given: A dataset identifier
        let datasetIdentifier = "test-persistence"
        
        // When: Updating status to completed
        await downloadService.updateDownloadStatus(datasetIdentifier: datasetIdentifier, status: .completed)
        
        // Then: Status should be persisted and retrievable
        let status = downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertEqual(status?.downloadStatus, .completed, "Status should be persisted")
        
        // When: Creating a new DownloadService instance (simulating app restart)
        let newDownloadService = DownloadService()
        
        // Then: The completed state should be restored
        let restoredStatus = newDownloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
        XCTAssertEqual(restoredStatus?.downloadStatus, .completed, "Completed status should persist across app restart")
    }
    
    func testViewModelRefreshStatusWithLocalFile() async {
        // Given: A dataset with a local file
        let datasetIdentifier = "test-viewmodel-refresh"
        
        // Create a test file
        let testData = "test data".data(using: .utf8)!
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let testFileURL = documentsPath.appendingPathComponent("\(datasetIdentifier).gpkg")
        try! testData.write(to: testFileURL)
        
        // Mock the localFileExists method to return true for our test file
        // This is a bit tricky without dependency injection, but let's test the logic
        
        // When: Refreshing status
        viewModel.refreshStatus(for: datasetIdentifier)
        
        // Then: Status should be completed
        let status = viewModel.status(for: datasetIdentifier)
        XCTAssertEqual(status?.downloadStatus, .completed, "ViewModel should show completed status for local file")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testFileURL)
    }
}
