# SHA512 Services

This folder contains reusable SHA512 checksum functionality that can be used across the entire app, not just for offline maps.

## Services

### SHA512Utilities.swift
- **Purpose**: Core SHA512 checksum calculation utilities
- **Dependencies**: Swift Crypto framework
- **Usage**: Calculate SHA512 checksums for any file

### SHA512ChecksumService.swift
- **Purpose**: Manage local SHA512 checksums with persistence
- **Features**: 
  - Calculate and store checksums
  - Retrieve stored checksums
  - Remove checksums
  - Automatic persistence to disk
- **Usage**: Any feature that needs to track file integrity

### SHA512DownloadService.swift
- **Purpose**: Download and manage remote SHA512 checksum files
- **Features**:
  - Download .sha512 files from remote URLs
  - Parallel downloads
  - Automatic persistence
- **Usage**: Any feature that needs to compare with remote checksums

### UpdateDetectionService.swift
- **Purpose**: Orchestrate update detection by comparing local and remote checksums
- **Features**:
  - Compare local vs remote checksums
  - File existence checks
  - Update availability detection
- **Usage**: Any feature that needs to detect when files need updating

## Usage Example

```swift
// Calculate checksum for a file
let checksum = SHA512Utilities.calculateSHA512(forFileAt: fileURL)

// Store checksum
let service = SHA512ChecksumService()
await service.calculateAndStoreChecksum(forFileAt: fileURL, datasetIdentifier: "my-file")

// Check for updates
let updateService = UpdateDetectionService(
    sha512ChecksumService: checksumService,
    sha512DownloadService: downloadService,
    downloadService: fileService
)
await updateService.checkForUpdates(for: ["my-file"])
```

## Dependencies

- Swift Crypto (for SHA512 calculation)
- Alamofire (for HTTP downloads)
- Combine (for reactive programming)
