import Foundation
import Combine

/// Service for detecting updates by comparing local and remote SHA512 checksums
@MainActor
public class UpdateDetectionService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var isCheckingForUpdates = false
    @Published public var lastUpdateCheck: Date?
    @Published public var updateResults: [String: Bool] = [:]
    @Published public var hasUpdates = false
    @Published public var updateCount = 0
    
    // MARK: - Private Properties
    
    private let sha512ChecksumService: SHA512ChecksumService
    private let sha512DownloadService: SHA512DownloadService
    private let downloadService: DownloadService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(
        sha512ChecksumService: SHA512ChecksumService,
        sha512DownloadService: SHA512DownloadService,
        downloadService: DownloadService
    ) {
        self.sha512ChecksumService = sha512ChecksumService
        self.sha512DownloadService = sha512DownloadService
        self.downloadService = downloadService
        
        setupServiceObservers()
    }
    
    // MARK: - Public Methods
    
    /// Perform a complete update check for all datasets
    public func checkForUpdates(for datasetIdentifiers: [String]) async {
        guard !datasetIdentifiers.isEmpty else {
            return
        }
        
        isCheckingForUpdates = true
        lastUpdateCheck = Date()
        
        // Download remote checksums
        await sha512DownloadService.checkForUpdates(for: datasetIdentifiers)
        
        // Compare local and remote checksums
        for identifier in datasetIdentifiers {
            let localChecksum = sha512ChecksumService.getLocalChecksum(for: identifier)
            let remoteChecksum = sha512DownloadService.getRemoteChecksum(for: identifier)
            let localFileExists = downloadService.localFileExists(for: identifier)
            
            let updateAvailable: Bool
            if localFileExists {
                // Only check for updates if local file exists
                var checksumDiffers = false
                var sizeDiffers = false
                
                // Check SHA512 checksum difference
                if let local = localChecksum, let remote = remoteChecksum {
                    checksumDiffers = local.lowercased() != remote.lowercased()
                } else if localChecksum == nil && remoteChecksum != nil {
                    // Local file exists but no local checksum - this means we need to calculate it or it's an update
                    checksumDiffers = true
                }
                
                // Check file size difference (if we have remote file size)
                if let _ = downloadService.localFileSize(for: identifier) {
                    // For now, we'll skip size comparison since we don't have remote file sizes
                    // This could be added later if needed
                    sizeDiffers = false
                }
                
                updateAvailable = checksumDiffers || sizeDiffers
            } else {
                // No local file, no update available
                updateAvailable = false
            }
            
            updateResults[identifier] = updateAvailable
        }
        
        updateCount = updateResults.values.filter { $0 }.count
        hasUpdates = updateCount > 0
        isCheckingForUpdates = false
    }
    
    /// Check for updates for a specific dataset
    public func checkForUpdate(for datasetIdentifier: String) async -> Bool {
        await checkForUpdates(for: [datasetIdentifier])
        return updateResults[datasetIdentifier] ?? false
    }
    
    /// Get all datasets with updates available
    public func getDatasetsWithUpdates() -> [String] {
        return updateResults.compactMap { $0.value ? $0.key : nil }
    }
    
    // MARK: - Private Methods
    
    private func setupServiceObservers() {
        // Monitor changes in local checksums
        sha512ChecksumService.$localChecksums
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Monitor changes in remote checksums
        sha512DownloadService.$remoteChecksums
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
