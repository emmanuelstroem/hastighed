import Foundation
import Alamofire
import Combine

/// A clean, reliable download service using Alamofire's native pause/resume functionality
@MainActor
public class DownloadService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var downloadItemsByIdentifier: [String: DownloadItem] = [:]
    
    // MARK: - Private Properties
    
    private let session: Session
    private let datasets: [DatasetListing]
    private var downloadTasks: [String: DownloadRequest] = [:]
    private var resumeDataCache: [String: Data] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let fileManager = FileManager.default
    private let persistenceFileName = "download_state.json"
    
    // MARK: - Initialization
    
    public init(datasets: [DatasetListing] = DatasetListing.allDatasets) {
        self.datasets = datasets
        
        // Configure Alamofire session for downloads
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60  // Increased from 30 to 60 seconds
        configuration.timeoutIntervalForResource = 600 // Increased from 300 to 600 seconds (10 minutes)
        configuration.waitsForConnectivity = true
        
        self.session = Session(configuration: configuration)
        
        // Load persisted state
        loadPersistedState()
        
        // Clean up any orphaned resume data or files on startup
        cleanupOrphanedData()
    }
    
    // MARK: - Public Interface
    
    /// Start a download for a dataset
    public func startDownload(for datasetIdentifier: String) {
        guard let dataset = datasets.first(where: { $0.datasetIdentifier == datasetIdentifier }),
              let url = URL(string: dataset.remoteResourceAddress) else {
            updateDownloadStatus(datasetIdentifier: datasetIdentifier, status: .failed, error: "Invalid dataset or URL")
            return
        }
        
        // If already downloading or completed, do nothing
        if let currentItem = downloadItemsByIdentifier[datasetIdentifier],
           [.downloading, .completed].contains(currentItem.downloadStatus) {
            return
        }
        
        
        // Update status to downloading
        updateDownloadStatus(datasetIdentifier: datasetIdentifier, status: .downloading)
        
        let directoryURL = applicationSupportDirectory.appendingPathComponent("OfflineMaps")
        let destinationURL = directoryURL.appendingPathComponent("\(datasetIdentifier).gpkg")
        
        // Ensure directory exists
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        
        let destination: DownloadRequest.Destination = { _, _ in
            return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let downloadRequest: DownloadRequest
        if let resumeData = resumeDataCache[datasetIdentifier] {
            // Resume from existing data
            downloadRequest = session.download(resumingWith: resumeData, to: destination)
        } else {
            // Start new download
            downloadRequest = session.download(url, to: destination)
        }
        
        downloadRequest
            .downloadProgress { [weak self] progress in
                Task { @MainActor in
                    self?.updateDownloadProgress(
                        datasetIdentifier: datasetIdentifier,
                        downloadedBytes: Int64(progress.completedUnitCount),
                        totalBytes: Int64(progress.totalUnitCount)
                    )
                }
            }
            .validate()
            .response { [weak self] response in
            Task { @MainActor in
                    self?.handleDownloadResponse(datasetIdentifier: datasetIdentifier, response: response)
                }
            }
        
        downloadTasks[datasetIdentifier] = downloadRequest
        downloadRequest.resume()
    }
    
        /// Pause a download
        public func pauseDownload(for datasetIdentifier: String) {
            guard let downloadRequest = downloadTasks[datasetIdentifier] else {
                return
            }
            
            
            // Update status to paused immediately
            updateDownloadStatus(datasetIdentifier: datasetIdentifier, status: .paused)
            
            downloadRequest.cancel { [weak self] resumeData in
                Task { @MainActor in
                    if let data = resumeData {
                        self?.resumeDataCache[datasetIdentifier] = data
                        // Persist the resume data cache immediately
                        self?.persistResumeDataCache()
                    } else {
                    }
                    self?.downloadTasks.removeValue(forKey: datasetIdentifier)
                    // Status is already set to paused above, no need to set it again
                }
            }
        }
    
    /// Resume a paused download
    public func resumeDownload(for datasetIdentifier: String) {
        guard let dataset = datasets.first(where: { $0.datasetIdentifier == datasetIdentifier }),
              let url = URL(string: dataset.remoteResourceAddress) else {
            updateDownloadStatus(datasetIdentifier: datasetIdentifier, status: .failed, error: "Invalid dataset or URL")
            return
        }
        
        // If already downloading or completed, do nothing
        if let currentItem = downloadItemsByIdentifier[datasetIdentifier],
           [.downloading, .completed].contains(currentItem.downloadStatus) {
            return
        }
        
        
        updateDownloadStatus(datasetIdentifier: datasetIdentifier, status: .downloading)
        
        let directoryURL = applicationSupportDirectory.appendingPathComponent("OfflineMaps")
        let destinationURL = directoryURL.appendingPathComponent("\(datasetIdentifier).gpkg")
        
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        
        let destination: DownloadRequest.Destination = { _, _ in
            return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let downloadRequest: DownloadRequest
        if let resumeData = resumeDataCache[datasetIdentifier] {
            downloadRequest = session.download(resumingWith: resumeData, to: destination)
        } else {
            downloadRequest = session.download(url, to: destination)
        }
        
        downloadRequest
            .downloadProgress { [weak self] progress in
                Task { @MainActor in
                    self?.updateDownloadProgress(
                        datasetIdentifier: datasetIdentifier,
                        downloadedBytes: Int64(progress.completedUnitCount),
                        totalBytes: Int64(progress.totalUnitCount)
                    )
                }
            }
            .validate()
            .response { [weak self] response in
                Task { @MainActor in
                    self?.handleDownloadResponse(datasetIdentifier: datasetIdentifier, response: response)
                }
            }
        
        downloadTasks[datasetIdentifier] = downloadRequest
        downloadRequest.resume()
    }
    
    
    /// Delete a downloaded file
    public func deleteLocalFile(for datasetIdentifier: String) {
        guard let url = storageURL(for: datasetIdentifier) else { return }
        
        do {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
            // Also remove any resume data
            resumeDataCache.removeValue(forKey: datasetIdentifier)
            downloadTasks[datasetIdentifier]?.cancel() // Cancel if active
            downloadTasks.removeValue(forKey: datasetIdentifier)
            updateDownloadStatus(datasetIdentifier: datasetIdentifier, status: .queued) // Reset status
        } catch {
            updateDownloadStatus(datasetIdentifier: datasetIdentifier, status: .failed, error: error.localizedDescription)
        }
    }
    
    /// Check if a local file exists
    public func localFileExists(for datasetIdentifier: String) -> Bool {
        guard let url = storageURL(for: datasetIdentifier) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    /// Get the size of a local file
    public func localFileSize(for datasetIdentifier: String) -> Int64? {
        guard let url = storageURL(for: datasetIdentifier) else { return nil }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
    
    /// Get the local file path for a dataset
    public func localFilePath(for datasetIdentifier: String) -> String? {
        return storageURL(for: datasetIdentifier)?.path
    }
    
    
    // MARK: - Private Methods
    
    private func updateDownloadProgress(datasetIdentifier: String, downloadedBytes: Int64, totalBytes: Int64) {
        guard var item = downloadItemsByIdentifier[datasetIdentifier] else { return }
        
        item.downloadedByteCount = downloadedBytes
        item.totalByteCount = totalBytes
        item.lastUpdatedAt = .now
        
        downloadItemsByIdentifier[datasetIdentifier] = item
    }
    
    private func updateDownloadStatus(datasetIdentifier: String, status: DownloadStatus, error: String? = nil) {
        var item = downloadItemsByIdentifier[datasetIdentifier] ?? DownloadItem(datasetIdentifier: datasetIdentifier, downloadStatus: .queued)
        
        item.downloadStatus = status
        item.lastUpdatedAt = .now
        if let error = error {
            item.lastErrorDescription = error
        }
        
        downloadItemsByIdentifier[datasetIdentifier] = item
        
        // Persist state
        persistState()
    }
    
    private func handleDownloadResponse(datasetIdentifier: String, response: DownloadResponse<URL?, AFError>) {
        downloadTasks.removeValue(forKey: datasetIdentifier)
        
        switch response.result {
        case .success(let url):
            if let url = url, FileManager.default.fileExists(atPath: url.path) {
                updateDownloadStatus(datasetIdentifier: datasetIdentifier, status: .completed)
            } else {
                updateDownloadStatus(datasetIdentifier: datasetIdentifier, status: .failed)
            }
            
        case .failure(let error):
            
            // Check if it's an explicit cancellation (pause) - don't treat as failure
            if let afError = error as? AFError,
               case .explicitlyCancelled = afError {
                // Don't update status here - it should already be set to paused
                return
            }
            
            // Check if it's a timeout error and provide better feedback
            if let afError = error as? AFError,
               case .sessionTaskFailed(let underlyingError) = afError,
               let urlError = underlyingError as? URLError,
               urlError.code == .timedOut {
            }
            
            updateDownloadStatus(datasetIdentifier: datasetIdentifier, status: .failed)
        }
    }
    
    private func storageURL(for datasetIdentifier: String) -> URL? {
        let directoryURL = applicationSupportDirectory.appendingPathComponent("OfflineMaps")
        return directoryURL.appendingPathComponent("\(datasetIdentifier).gpkg")
    }
    
    private func cleanupOrphanedData() {
        // Clean up any resume data that doesn't correspond to an active download or paused item
        let pausedIdentifiers = Set(downloadItemsByIdentifier.filter { $0.value.downloadStatus == .paused }.keys)
        let activeIdentifiers = Set(downloadTasks.keys)
        let validIdentifiers = pausedIdentifiers.union(activeIdentifiers)
        
        resumeDataCache = resumeDataCache.filter { validIdentifiers.contains($0.key) }
    }
    
    // MARK: - Persistence
    
    private func loadPersistedState() {
        do {
            guard fileManager.fileExists(atPath: persistenceURL.path) else {
                return
            }
            let data = try Data(contentsOf: persistenceURL)
            downloadItemsByIdentifier = try JSONDecoder().decode([String: DownloadItem].self, from: data)
            
            // Load resume data cache
            loadResumeDataCache()
            
            // Validate loaded state against local files
            for (identifier, item) in downloadItemsByIdentifier {
                if item.downloadStatus == .completed && !localFileExists(for: identifier) {
                    // If state says completed but file doesn't exist, mark as failed
                    updateDownloadStatus(datasetIdentifier: identifier, status: .failed, error: "File missing after completion")
                } else if item.downloadStatus != .completed && localFileExists(for: identifier) {
                    // If file exists but state is not completed, mark as completed
                    updateDownloadStatus(datasetIdentifier: identifier, status: .completed)
                }
            }
        } catch {
            // Attempt to clean up corrupted file
            try? fileManager.removeItem(at: persistenceURL)
        }
    }
    
    private func persistState() {
        do {
            let data = try JSONEncoder().encode(downloadItemsByIdentifier)
            try data.write(to: persistenceURL, options: [.atomicWrite])
            
            // Also persist resume data cache
            persistResumeDataCache()
        } catch {
        }
    }
    
    private var applicationSupportDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }
    
    private var persistenceURL: URL {
        applicationSupportDirectory.appendingPathComponent(persistenceFileName)
    }
    
    private var resumeDataCacheURL: URL {
        applicationSupportDirectory.appendingPathComponent("resume_data_cache.json")
    }
    
    private func persistResumeDataCache() {
        do {
            // Convert Data to base64 strings for JSON encoding
            let resumeDataStrings = resumeDataCache.mapValues { $0.base64EncodedString() }
            let data = try JSONEncoder().encode(resumeDataStrings)
            try data.write(to: resumeDataCacheURL, options: [.atomicWrite])
        } catch {
        }
    }
    
    private func loadResumeDataCache() {
        do {
            guard fileManager.fileExists(atPath: resumeDataCacheURL.path) else {
                return
            }
            let data = try Data(contentsOf: resumeDataCacheURL)
            let resumeDataStrings = try JSONDecoder().decode([String: String].self, from: data)
            
            // Convert base64 strings back to Data
            resumeDataCache = resumeDataStrings.compactMapValues { base64String in
                Data(base64Encoded: base64String)
            }
        } catch {
            // Attempt to clean up corrupted file
            try? fileManager.removeItem(at: resumeDataCacheURL)
        }
    }
}

// MARK: - Convenience Methods

extension DownloadService {
    
    /// Toggle download state (start/pause/resume)
    public func toggleDownloadState(for datasetIdentifier: String) {
        guard let item = downloadItemsByIdentifier[datasetIdentifier] else {
            // Start new download
            startDownload(for: datasetIdentifier)
            return
        }
        
        switch item.downloadStatus {
        case .downloading:
            pauseDownload(for: datasetIdentifier)
        case .paused:
            resumeDownload(for: datasetIdentifier)
        case .completed:
            // If completed, delete the file
            deleteLocalFile(for: datasetIdentifier)
        case .failed, .canceled, .queued:
            // Start new download
            startDownload(for: datasetIdentifier)
        }
    }
}
