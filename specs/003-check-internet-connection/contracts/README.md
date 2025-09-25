# Contracts: Connectivity & Country Context

## ConnectivityService
- isInternetUsable() -> Bool
- currentNetworkType() -> NetworkType (wifi | cellular | other | none)
- onStatusChange((ConnectivityStatus) -> Void)

## CountryContextProvider
- currentCountryCode() -> String (ISO 3166‑1 alpha‑2)
- onCountryChange((CountryContext) -> Void)
- setManualOverride(code: String?)

## DownloadPolicy
- shouldPromptForLargeDownload(networkType: NetworkType, sizeBytes: Int) -> Bool

## DownloadService
- enqueueDownload(url: URL, identifier: String) -> DownloadHandle
- pause(identifier: String)
- resume(identifier: String)
- cancel(identifier: String)
- cleanup(identifier: String)
- onProgress(identifier: String, handler: (bytesWritten: Int64, totalBytes: Int64) -> Void)
- onCompletion(identifier: String, handler: (Result<URL, Error>) -> Void)


