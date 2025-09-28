import Foundation
import Alamofire
import Combine

/// Service for downloading and managing remote .sha512 files
@MainActor
public class SHA512DownloadService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var remoteChecksums: [String: String] = [:]
    @Published public var lastUpdateCheck: Date?
    @Published public var isCheckingForUpdates = false
    
    // MARK: - Private Properties
    
    private let session: Session
    private let baseURL: String
    private let fileManager = FileManager.default
    private let applicationSupportDirectory: URL
    private let persistenceURL: URL
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(baseURL: String = "https://hastighed.stillestorm.dk") {
        self.baseURL = baseURL
        self.session = Session.default
        self.applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.persistenceURL = applicationSupportDirectory.appendingPathComponent("remote_sha512_checksums.json")
        
        loadRemoteChecksums()
    }
    
    // MARK: - Public Methods
    
    /// Check for updates by downloading .sha512 files for all datasets
    public func checkForUpdates(for datasetIdentifiers: [String]) async {
        guard !datasetIdentifiers.isEmpty else {
            print("⚠️ SHA512DownloadService: No datasets to check")
            return
        }
        
        isCheckingForUpdates = true
        lastUpdateCheck = Date()
        
        print("🔍 SHA512DownloadService: Checking for updates for \(datasetIdentifiers.count) datasets")
        
        let urls = datasetIdentifiers.compactMap { identifier in
            let url = generateSHA512URL(for: identifier)
            print("🔍 SHA512DownloadService: Generated URL for \(identifier): \(url?.absoluteString ?? "nil")")
            return url
        }
        
        let results = await downloadMultipleSHA512Files(from: urls)
        
        // Process results
        for (url, content) in results {
            print("🔍 SHA512DownloadService: Processing result from URL: \(url.absoluteString)")
            print("🔍 SHA512DownloadService: Content preview: \(String(content.prefix(100)))...")
            
            if let identifier = extractDatasetIdentifier(from: url) {
                let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                remoteChecksums[identifier] = trimmedContent
                print("✅ SHA512DownloadService: Downloaded checksum for \(identifier): \(trimmedContent)")
            } else {
                print("❌ SHA512DownloadService: Could not extract identifier from URL: \(url.absoluteString)")
            }
        }
        
        persistRemoteChecksums()
        isCheckingForUpdates = false
        
        print("✅ SHA512DownloadService: Update check completed. Found \(remoteChecksums.count) checksums")
    }
    
    /// Download a single .sha512 file for a given dataset identifier
    public func downloadChecksum(for datasetIdentifier: String) async -> String? {
        guard let url = generateSHA512URL(for: datasetIdentifier) else {
            print("❌ SHA512DownloadService: Invalid URL for dataset \(datasetIdentifier)")
            return nil
        }
        
        guard let content = await downloadSHA512File(from: url) else {
            print("❌ SHA512DownloadService: Failed to download .sha512 for \(datasetIdentifier)")
            return nil
        }
        
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        remoteChecksums[datasetIdentifier] = trimmedContent
        persistRemoteChecksums()
        print("✅ SHA512DownloadService: Downloaded and stored single checksum for \(datasetIdentifier)")
        return trimmedContent
    }
    
    /// Get the remote SHA512 checksum for a dataset
    public func getRemoteChecksum(for datasetIdentifier: String) -> String? {
        return remoteChecksums[datasetIdentifier]
    }
    
    // MARK: - Private Methods
    
    private func generateSHA512URL(for datasetIdentifier: String) -> URL? {
        let sha512FileName = "\(datasetIdentifier).gpkg.sha512"
        let fullURL = "\(baseURL)/\(sha512FileName)"
        return URL(string: fullURL)
    }
    
    private func downloadSHA512File(from url: URL) async -> String? {
        return await withCheckedContinuation { continuation in
            session.request(url)
                .validate()
                .responseString { response in
                    switch response.result {
                    case .success(let content):
                        print("✅ SHA512DownloadService: Successfully downloaded .sha512 file from \(url)")
                        continuation.resume(returning: content)
                    case .failure(let error):
                        print("❌ SHA512DownloadService: Failed to download .sha512 file from \(url): \(error)")
                        continuation.resume(returning: nil)
                    }
                }
        }
    }
    
    private func downloadMultipleSHA512Files(from urls: [URL]) async -> [URL: String] {
        var results: [URL: String] = [:]
        await withTaskGroup(of: (URL, String?).self) { group in
            for url in urls {
                group.addTask {
                    let content = await self.downloadSHA512File(from: url)
                    return (url, content)
                }
            }
            for await (url, content) in group {
                if let content = content {
                    results[url] = content
                }
            }
        }
        return results
    }
    
    private func extractDatasetIdentifier(from url: URL) -> String? {
        let fileName = url.lastPathComponent
        // Expecting format like "liechtenstein.gpkg.sha512"
        let components = fileName.split(separator: ".").dropLast(2) // Remove .sha512 and .gpkg
        guard let identifier = components.first else { return nil }
        return String(identifier)
    }
    
    // MARK: - Persistence
    
    private func loadRemoteChecksums() {
        do {
            let data = try Data(contentsOf: persistenceURL)
            let decodedChecksums = try JSONDecoder().decode([String: String].self, from: data)
            self.remoteChecksums = decodedChecksums
            print("✅ SHA512DownloadService: Loaded \(remoteChecksums.count) remote checksums from disk.")
        } catch {
            print("⚠️ SHA512DownloadService: Failed to load remote checksums: \(error.localizedDescription). Starting fresh.")
            self.remoteChecksums = [:]
        }
    }
    
    private func persistRemoteChecksums() {
        do {
            let data = try JSONEncoder().encode(remoteChecksums)
            try data.write(to: persistenceURL, options: [.atomicWrite])
            print("💾 SHA512DownloadService: Persisted \(remoteChecksums.count) remote checksums to disk.")
        } catch {
            print("❌ SHA512DownloadService: Failed to persist remote checksums: \(error.localizedDescription)")
        }
    }
}
