import Foundation
import Combine

@MainActor
final class OfflineMapsViewModel: ObservableObject {
    @Published var datasetListings: [DatasetListing] = []
    @Published var downloadItemsByIdentifier: [String: DownloadItem] = [:]

    private let downloadService: DownloadServiceProtocol

    init(downloadService: DownloadServiceProtocol) {
        self.downloadService = downloadService
        self.datasetListings = downloadService.listAvailableDatasets()
    }

    func startDownload(for datasetIdentifier: String) {
        Task {
            await downloadService.startDatasetDownload(datasetIdentifier: datasetIdentifier, userConfirmedCellularDownload: true)
            await MainActor.run { self.refreshStatus(for: datasetIdentifier) }
        }
    }

    func pauseDownload(for datasetIdentifier: String) {
        Task {
            await downloadService.pauseDatasetDownload(datasetIdentifier: datasetIdentifier)
            await MainActor.run { self.refreshStatus(for: datasetIdentifier) }
        }
    }
    func resumeDownload(for datasetIdentifier: String) {
        Task {
            await downloadService.resumeDatasetDownload(datasetIdentifier: datasetIdentifier)
            await MainActor.run { self.refreshStatus(for: datasetIdentifier) }
        }
    }
    func toggleDownloadPause(for datasetIdentifier: String) {
        if status(for: datasetIdentifier)?.downloadStatus == .downloading {
            pauseDownload(for: datasetIdentifier)
        } else {
            // For idle or paused, start/resume using the Download icon semantics
            startDownload(for: datasetIdentifier)
        }
    }
    // Cancel action removed per updated plan; keep API available but unused
    func cancelDownload(for datasetIdentifier: String) {
        Task {
            await downloadService.cancelDatasetDownload(datasetIdentifier: datasetIdentifier)
            await MainActor.run { self.refreshStatus(for: datasetIdentifier) }
        }
    }
    func deleteLocalFile(for datasetIdentifier: String) {
        Task {
            try? await downloadService.deleteLocalDatasetFile(datasetIdentifier: datasetIdentifier)
            await MainActor.run { self.refreshStatus(for: datasetIdentifier) }
        }
    }

    func status(for datasetIdentifier: String) -> DownloadItem? {
        downloadItemsByIdentifier[datasetIdentifier]
    }

    private func refreshStatus(for datasetIdentifier: String) {
        downloadItemsByIdentifier[datasetIdentifier] = downloadService.getDatasetDownloadStatus(datasetIdentifier: datasetIdentifier)
    }
}


