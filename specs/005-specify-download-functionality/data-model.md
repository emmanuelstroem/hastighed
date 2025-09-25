# Data Model: Manage GPKG Downloads in Settings

## Entities

### DatasetListing
- description: A dataset available for download, typically representing a country.
- fields:
  - datasetIdentifier: String (unique, full word "identifier")
  - countryName: String
  - versionLabel: String (optional)
  - expectedTotalByteCount: Int64 (if known)
  - remoteResourceAddress: String (address of the remote file)
  - lastUpdatedDateDescription: String (optional)

### DownloadItem
- description: The lifecycle and state of a dataset download.
- fields:
  - datasetIdentifier: String
  - downloadStatus: Enum { queued, downloading, paused, completed, failed, canceled }
  - downloadedByteCount: Int64
  - totalByteCount: Int64 (if known; equals expectedTotalByteCount when available)
  - progressFraction: Double (derived: downloadedByteCount / totalByteCount when known)
  - lastUpdatedAt: Date
  - lastErrorDescription: String (optional)

### LocalGpkgFile
- description: A downloaded on-device GPKG file.
- fields:
  - datasetIdentifier: String
  - localFilePath: String (absolute path within the app container, e.g., Application Support)
  - localFileSizeByteCount: Int64
  - lastUpdatedAt: Date
  - integrityStateDescription: String (e.g., "validated-bytes", "checksum-unknown")
  - shouldPersistAcrossUpdates: Bool (always true; removed only when user deletes)

### DownloadPolicy
- description: Policy governing network and size constraints for downloads.
- fields:
  - cellularConfirmationThresholdByteCount: Int64 (default: 50 * 1024 * 1024)
  - currentConnectivityTypeDescription: String (e.g., "wifi", "cellular", "offline")
  - requiresUserConfirmationOnCellularForLargeFiles: Bool (derived from threshold and size)

## State Transitions

```
idle → queued → downloading → (paused ↔ downloading) → completed
downloading → canceled
downloading → failed
paused → canceled
completed → deleted (removes LocalGpkgFile; item returns to idle)
```

Rules:
- Only one active `downloading` at a time; others remain `queued`.
- Cancel removes any partial local files.
- Delete (from completed) removes the local file and returns the item to idle.
- For datasets with expectedTotalByteCount greater than cellularConfirmationThresholdByteCount and connectivity type is cellular, require explicit user confirmation before starting or resuming.
 - LocalGpkgFile resides in the app’s sandboxed Application Support directory to persist across app updates.


