import Foundation

public enum DownloadStatus: String, Codable, Equatable {
    case queued
    case downloading
    case paused
    case completed
    case failed
    case canceled
}

public struct DownloadItem: Codable, Equatable, Hashable {
    public let datasetIdentifier: String
    public var downloadStatus: DownloadStatus
    public var downloadedByteCount: Int64
    public var totalByteCount: Int64?
    public var lastUpdatedAt: Date
    public var lastErrorDescription: String?
    
    /// Whether an update is available for this dataset
    public var updateAvailable: Bool?
    
    /// The local SHA512 checksum of the downloaded file
    public var localSHA512Checksum: String?
    
    /// The remote SHA512 checksum from the .sha512 file
    public var remoteSHA512Checksum: String?
    
    /// The timestamp when the update check was last performed
    public var lastUpdateCheckAt: Date?

    public var progressFraction: Double? {
        guard let total = totalByteCount, total > 0 else { return nil }
        return min(1.0, max(0.0, Double(downloadedByteCount) / Double(total)))
    }
    
    /// Whether the local and remote SHA512 checksums match
    public var checksumsMatch: Bool {
        guard let local = localSHA512Checksum,
              let remote = remoteSHA512Checksum else {
            return false
        }
        return local.lowercased() == remote.lowercased()
    }
    
    /// Whether an update is available (with default false if not set)
    public var isUpdateAvailable: Bool {
        return updateAvailable ?? false
    }

    public init(
        datasetIdentifier: String,
        downloadStatus: DownloadStatus,
        downloadedByteCount: Int64 = 0,
        totalByteCount: Int64? = nil,
        lastUpdatedAt: Date = .now,
        lastErrorDescription: String? = nil,
        updateAvailable: Bool? = nil,
        localSHA512Checksum: String? = nil,
        remoteSHA512Checksum: String? = nil,
        lastUpdateCheckAt: Date? = nil
    ) {
        self.datasetIdentifier = datasetIdentifier
        self.downloadStatus = downloadStatus
        self.downloadedByteCount = downloadedByteCount
        self.totalByteCount = totalByteCount
        self.lastUpdatedAt = lastUpdatedAt
        self.lastErrorDescription = lastErrorDescription
        self.updateAvailable = updateAvailable
        self.localSHA512Checksum = localSHA512Checksum
        self.remoteSHA512Checksum = remoteSHA512Checksum
        self.lastUpdateCheckAt = lastUpdateCheckAt
    }
    
    // MARK: - Update Methods
    
    /// Create a new instance with updated SHA512 checksums
    public func withSHA512Checksums(
        local: String?,
        remote: String?
    ) -> DownloadItem {
        var updated = self
        updated.localSHA512Checksum = local
        updated.remoteSHA512Checksum = remote
        updated.updateAvailable = (local != nil && remote != nil && local?.lowercased() != remote?.lowercased())
        updated.lastUpdateCheckAt = Date()
        return updated
    }
    
    /// Create a new instance with update availability status
    public func withUpdateAvailable(_ available: Bool) -> DownloadItem {
        var updated = self
        updated.updateAvailable = available
        updated.lastUpdateCheckAt = Date()
        return updated
    }
}


