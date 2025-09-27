import Foundation
import Combine

@MainActor
public class OfflineMapsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var datasetListings: [DatasetListing] = []
    @Published public var localFileAvailability: Set<String> = []
    
    // MARK: - Private Properties
    
    private let downloadService: DownloadService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init() {
        self.downloadService = DownloadService()
        
        // Set up data
        self.datasetListings = DatasetListing.allDatasets
        
        // Listen to download service changes
        downloadService.$downloadItemsByIdentifier
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Initial refresh
        refreshAllStatuses()
    }
    
    // MARK: - Public Interface
    
    /// Get download status for a dataset
    public func status(for datasetIdentifier: String) -> DownloadItem? {
        return downloadService.downloadItemsByIdentifier[datasetIdentifier]
    }
    
    /// Check if a local file exists
    public func localFileExists(for datasetIdentifier: String) -> Bool {
        return downloadService.localFileExists(for: datasetIdentifier)
    }
    
    /// Check if a download can be paused
    public func canPauseDownload(for datasetIdentifier: String) -> Bool {
        return downloadService.canPauseDownload(for: datasetIdentifier)
    }
    
    /// Start a download
    public func startDownload(for datasetIdentifier: String) {
        downloadService.startDownload(for: datasetIdentifier, userConfirmedCellularDownload: true)
    }
    
    /// Pause a download
    public func pauseDownload(for datasetIdentifier: String) {
        downloadService.pauseDownload(for: datasetIdentifier)
    }
    
    /// Resume a download
    public func resumeDownload(for datasetIdentifier: String) {
        downloadService.resumeDownload(for: datasetIdentifier)
    }
    
    /// Cancel a download
    public func cancelDownload(for datasetIdentifier: String) {
        downloadService.cancelDownload(for: datasetIdentifier)
    }
    
    /// Delete a local file
    public func deleteLocalFile(for datasetIdentifier: String) {
        downloadService.deleteLocalFile(for: datasetIdentifier)
        refreshLocalFiles()
    }
    
    /// Toggle download state (start/pause/resume/delete)
    public func toggleDownloadPause(for datasetIdentifier: String) {
        downloadService.toggleDownloadState(for: datasetIdentifier)
        refreshLocalFiles()
    }
    
    /// Refresh all statuses
    public func refreshAllStatuses() {
        refreshLocalFiles()
    }
    
    /// Get file size for a dataset
    public func fileSize(for datasetIdentifier: String) -> Int64? {
        // First check local file size
        if let localSize = downloadService.localFileSize(for: datasetIdentifier) {
            return localSize
        }
        
        // Fall back to expected size from dataset listing
        return datasetListings.first { $0.datasetIdentifier == datasetIdentifier }?.expectedTotalByteCount
    }
    
    // MARK: - Private Methods
    
    private func refreshLocalFiles() {
        var updated = Set<String>()
        for listing in datasetListings {
            if downloadService.localFileExists(for: listing.datasetIdentifier) {
                updated.insert(listing.datasetIdentifier)
            }
        }
        localFileAvailability = updated
    }
}