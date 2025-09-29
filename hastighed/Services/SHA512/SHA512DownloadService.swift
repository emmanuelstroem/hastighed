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
            return
        }
        
        isCheckingForUpdates = true
        lastUpdateCheck = Date()
        
        for identifier in datasetIdentifiers {
            guard let url = generateSHA512URL(for: identifier) else {
                continue
            }
            downloadSHA512(for: identifier, from: url)
        }
        
        persistRemoteChecksums()
        isCheckingForUpdates = false
    }
    
    /// Download a single .sha512 file for a given dataset identifier
    public func downloadChecksum(for datasetIdentifier: String) async -> String? {
        guard let url = generateSHA512URL(for: datasetIdentifier) else {
            return nil
        }
        
        guard let content = await downloadSHA512File(from: url) else {
            return nil
        }
        
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        remoteChecksums[datasetIdentifier] = trimmedContent
        persistRemoteChecksums()
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
                        continuation.resume(returning: content)
                    case .failure(let error):
                        print("Error downloading SHA512 file: \(error.localizedDescription)")
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
    
    private func downloadSHA512(for datasetIdentifier: String, from url: URL) {
        session.request(url)
            .validate()
            .responseString { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let content):
                    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.remoteChecksums[datasetIdentifier] = trimmedContent
                    self.persistRemoteChecksums()
                case .failure:
                    self.remoteChecksums.removeValue(forKey: datasetIdentifier)
                }
            }
    }
    
    // MARK: - Persistence
    
    private func loadRemoteChecksums() {
        do {
            let data = try Data(contentsOf: persistenceURL)
            let decodedChecksums = try JSONDecoder().decode([String: String].self, from: data)
            self.remoteChecksums = decodedChecksums
        } catch {
            self.remoteChecksums.removeAll()
        }
    }
    
    private func persistRemoteChecksums() {
        do {
            let data = try JSONEncoder().encode(remoteChecksums)
            try data.write(to: persistenceURL, options: [.atomicWrite])
        } catch {
        }
    }
}
