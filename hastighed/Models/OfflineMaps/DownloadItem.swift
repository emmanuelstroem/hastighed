import Foundation

public enum DownloadStatus: String, Equatable {
    case queued
    case downloading
    case paused
    case completed
    case failed
    case canceled
}

public struct DownloadItem: Equatable, Hashable {
    public let datasetIdentifier: String
    public var downloadStatus: DownloadStatus
    public var downloadedByteCount: Int64
    public var totalByteCount: Int64?
    public var lastUpdatedAt: Date
    public var lastErrorDescription: String?

    public var progressFraction: Double? {
        guard let total = totalByteCount, total > 0 else { return nil }
        return min(1.0, max(0.0, Double(downloadedByteCount) / Double(total)))
    }

    public init(
        datasetIdentifier: String,
        downloadStatus: DownloadStatus,
        downloadedByteCount: Int64 = 0,
        totalByteCount: Int64? = nil,
        lastUpdatedAt: Date = .now,
        lastErrorDescription: String? = nil
    ) {
        self.datasetIdentifier = datasetIdentifier
        self.downloadStatus = downloadStatus
        self.downloadedByteCount = downloadedByteCount
        self.totalByteCount = totalByteCount
        self.lastUpdatedAt = lastUpdatedAt
        self.lastErrorDescription = lastErrorDescription
    }
}


