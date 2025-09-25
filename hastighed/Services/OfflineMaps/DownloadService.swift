import Foundation

public protocol DownloadServiceProtocol {
    func listAvailableDatasets() -> [DatasetListing]
    func startDatasetDownload(datasetIdentifier: String, userConfirmedCellularDownload: Bool) async
    func pauseDatasetDownload(datasetIdentifier: String) async
    func resumeDatasetDownload(datasetIdentifier: String) async
    func cancelDatasetDownload(datasetIdentifier: String) async
    func deleteLocalDatasetFile(datasetIdentifier: String) async throws
    func getDatasetDownloadStatus(datasetIdentifier: String) -> DownloadItem?
}

public final class DownloadService: DownloadServiceProtocol {
    private var downloadItemsByIdentifier: [String: DownloadItem] = [:]

    public init() {}

    public func listAvailableDatasets() -> [DatasetListing] {
        // Minimal seed for scaffolding; later populated from remote catalog
        return [
            DatasetListing(
                datasetIdentifier: "denmark",
                countryName: "Denmark",
                expectedTotalByteCount: nil,
                remoteResourceAddress: "http://hastighed.stillestorm.dk/denmark.gpkg"
            ),
            DatasetListing(
                datasetIdentifier: "sweden",
                countryName: "Sweden",
                expectedTotalByteCount: nil,
                remoteResourceAddress: "http://hastighed.stillestorm.dk/sweden.gpkg"
            )
        ]
    }

    public func startDatasetDownload(datasetIdentifier: String, userConfirmedCellularDownload: Bool) async {
        // For scaffolding: transition to downloading
        let existing = downloadItemsByIdentifier[datasetIdentifier]
        let total: Int64? = existing?.totalByteCount ?? 100
        downloadItemsByIdentifier[datasetIdentifier] = DownloadItem(
            datasetIdentifier: datasetIdentifier,
            downloadStatus: .downloading,
            downloadedByteCount: existing?.downloadedByteCount ?? 0,
            totalByteCount: total,
            lastUpdatedAt: .now
        )
    }

    public func pauseDatasetDownload(datasetIdentifier: String) async {
        guard var item = downloadItemsByIdentifier[datasetIdentifier] else { return }
        item.downloadStatus = .paused
        item.lastUpdatedAt = .now
        downloadItemsByIdentifier[datasetIdentifier] = item
    }

    public func resumeDatasetDownload(datasetIdentifier: String) async {
        guard var item = downloadItemsByIdentifier[datasetIdentifier] else { return }
        item.downloadStatus = .downloading
        item.lastUpdatedAt = .now
        downloadItemsByIdentifier[datasetIdentifier] = item
    }

    public func cancelDatasetDownload(datasetIdentifier: String) async {
        // Remove partial data and reset to idle state
        downloadItemsByIdentifier.removeValue(forKey: datasetIdentifier)
    }

    public func deleteLocalDatasetFile(datasetIdentifier: String) async throws {
        // Scaffolding: no-op (would remove file at resolved path)
        downloadItemsByIdentifier.removeValue(forKey: datasetIdentifier)
    }

    public func getDatasetDownloadStatus(datasetIdentifier: String) -> DownloadItem? {
        downloadItemsByIdentifier[datasetIdentifier]
    }
}


