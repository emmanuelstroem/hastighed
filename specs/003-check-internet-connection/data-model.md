# Data Model: Connectivity & Country Context

## Entities

### ConnectivityStatus
- usable: Boolean (true if downloads are allowed)
- reason: Enum { online, offline, captive_portal, host_unreachable, constrained }
- networkType: Enum { wifi, cellular, other, none }
- lastCheckedAt: Timestamp

### CountryContext
- isoCountryCode: String (ISO 3166‑1 alpha‑2)
- source: Enum { automatic_location, manual_selection, device_setting }
- confidence: Enum { high, medium, low }
- lastUpdatedAt: Timestamp

### PackageCatalogEntry
- countryCode: String
- packageId: String
- name: String
- version: String
- sizeBytes: Integer
- lastUpdatedAt: Timestamp

### DownloadRequest
- packageId: String
- status: Enum { queued, downloading, paused, resumed, completed, failed }
- bytesDownloaded: Integer
- errorReason: Optional String
- startedAt: Timestamp
- completedAt: Optional Timestamp

### DownloadRecord
- identifier: String
- url: URL
- localFileURL: Optional URL
- resumeData: Optional Data
- totalBytes: Optional Integer
- writtenBytes: Integer
- state: Enum { queued, downloading, paused, completed, failed, cancelled }


