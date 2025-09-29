import Foundation
import Combine
import CryptoKit

/// Service for managing local SHA512 checksums for downloaded files
@MainActor
public class SHA512ChecksumService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var localChecksums: [String: String] = [:]
    
    // MARK: - Private Properties
    
    private let appSupportDirectory: URL
    private let persistenceFileName = "sha512checksums.json"
    
    nonisolated public init() {
        let fileManager = FileManager.default
        self.appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        // Load checksums on main actor
        Task { @MainActor in
            loadLocalChecksums()
        }
    }
    
    /// Calculates and stores the SHA512 checksum for a given local file
    public func calculateChecksum(for datasetIdentifier: String, fileURL: URL) async throws -> String {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw SHA512ChecksumError.fileNotFound
        }
        
        guard let checksum = SHA512Utilities.calculateSHA512(forFileAt: fileURL) else {
            throw SHA512ChecksumError.hashFailed
        }
        
        localChecksums[datasetIdentifier] = checksum
        persistLocalChecksums()
        return checksum
    }
    
    /// Retrieves the stored local SHA512 checksum for a dataset
    public func getLocalChecksum(for datasetIdentifier: String) -> String? {
        return localChecksums[datasetIdentifier]
    }
    
    /// Remove a local checksum
    public func removeChecksum(for datasetIdentifier: String) {
        localChecksums.removeValue(forKey: datasetIdentifier)
        persistLocalChecksums()
    }
    
    // MARK: - Persistence
    
    private var persistenceURL: URL {
        return appSupportDirectory.appendingPathComponent(persistenceFileName)
    }
    
    private func loadLocalChecksums() {
        do {
            let data = try Data(contentsOf: persistenceURL)
            let decodedChecksums = try JSONDecoder().decode([String: String].self, from: data)
            self.localChecksums = decodedChecksums
        } catch {
            localChecksums = [:]
        }
    }
    
    private func persistLocalChecksums() {
        do {
            let data = try JSONEncoder().encode(localChecksums)
            try data.write(to: persistenceURL, options: [.atomicWrite])
        } catch {
        }
    }
}

public enum SHA512ChecksumError: Error {
    case fileNotFound
    case hashFailed
}
