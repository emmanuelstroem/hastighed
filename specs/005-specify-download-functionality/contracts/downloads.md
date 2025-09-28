# Service Contracts: Downloads

All function names and parameter names use full words (no abbreviations). Return values are modeled for planning and test generation; implementation details are out of scope here.

## List Datasets
- name: listAvailableDatasets
- parameters: none
- returns: [DatasetListing]

## Start Download
- name: startDatasetDownload
- parameters:
  - datasetIdentifier: String
  - userConfirmedCellularDownload: Bool (required when expectedTotalByteCount > 50MB and connectivity type is cellular)
- returns: DownloadItem (status: queued or downloading)

## Toggle Download/Pause
- name: toggleDatasetDownloadState
- parameters:
  - datasetIdentifier: String
- returns: DownloadItem (status: downloading|paused)

Note: Resume is represented by toggling from paused to downloading using the same control; UI shows Download icon.

## Cancel Download
- name: cancelDatasetDownload
- parameters:
  - datasetIdentifier: String
- returns: DownloadItem (status: canceled) and side-effect: remove partial local files

## Delete Local File
- name: deleteLocalDatasetFile
- parameters:
  - datasetIdentifier: String
- returns: void; side-effect: remove local GPKG file if present

## Resolve Local Storage Location
- name: resolveLocalDatasetStorageLocation
- parameters:
  - datasetIdentifier: String
- returns: localFilePath within the app container (Application Support preferred)

## Observe Progress
- name: observeDatasetDownloadProgress
- parameters:
  - datasetIdentifier: String
- returns: stream of (downloadedByteCount: Int64, totalByteCount: Int64?) until completion or failure

## Evaluate Network Policy
- name: evaluateDatasetDownloadNetworkPolicy
- parameters:
  - datasetIdentifier: String
- returns: policy requiring confirmation (requiresUserConfirmationOnCellularForLargeFiles: Bool, cellularConfirmationThresholdByteCount: Int64, currentConnectivityTypeDescription: String)

## Status Inquiry
- name: getDatasetDownloadStatus
- parameters:
  - datasetIdentifier: String
- returns: DownloadItem


