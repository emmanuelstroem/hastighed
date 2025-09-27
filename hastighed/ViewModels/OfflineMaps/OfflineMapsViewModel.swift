import Foundation
import Combine

@MainActor
public class OfflineMapsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var datasetListings: [DatasetListing] = []
    @Published public var localFileAvailability: Set<String> = []
    @Published public var remoteFileSizes: [String: Int64] = [:]
    
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
        
        // Fall back to cached remote file size
        return remoteFileSizes[datasetIdentifier]
    }
    
    /// Fetch remote file size for a dataset
    public func fetchRemoteFileSize(for datasetIdentifier: String) async -> Int64? {
        guard let dataset = datasetListings.first(where: { $0.datasetIdentifier == datasetIdentifier }) else {
            return nil
        }
        
        do {
            let url = URL(string: dataset.remoteResourceAddress)!
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD" // Only get headers, not the full file
            request.timeoutInterval = 10.0
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
               let size = Int64(contentLength) {
                // Cache the result
                remoteFileSizes[datasetIdentifier] = size
                return size
            }
        } catch {
            print("⚠️ Failed to fetch remote file size for \(datasetIdentifier): \(error)")
        }
        
        return nil
    }
    
    /// Fetch remote file sizes for all datasets
    public func fetchAllRemoteFileSizes() async {
        await withTaskGroup(of: Void.self) { group in
            for dataset in datasetListings {
                group.addTask {
                    await self.fetchRemoteFileSize(for: dataset.datasetIdentifier)
                }
            }
        }
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