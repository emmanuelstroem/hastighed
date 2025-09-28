import Foundation
import Combine
import CryptoKit

/// Service for managing local SHA512 checksums for downloaded files
@MainActor
public class SHA512ChecksumService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var localChecksums: [String: String] = [:]
    
    // MARK: - Private Properties
    
    private let fileManager: FileManager
    private let appSupportDirectory: URL
    private let persistenceFileName = "sha512checksums.json"
    
    nonisolated public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        // Load checksums on main actor
        Task { @MainActor in
            loadLocalChecksums()
        }
    }
    
    /// Calculates and stores the SHA512 checksum for a given local file
    public func calculateAndStoreChecksum(forFileAt fileURL: URL, datasetIdentifier: String) async -> String? {
        print("🔍 SHA512ChecksumService: Starting checksum calculation for \(datasetIdentifier)")
        print("🔍 SHA512ChecksumService: File path: \(fileURL.path)")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("⚠️ SHA512ChecksumService: File does not exist at \(fileURL.path)")
            return nil
        }
        
        print("🔍 SHA512ChecksumService: File exists, calculating SHA512...")
        guard let sha512 = SHA512Utilities.calculateSHA512(forFileAt: fileURL) else {
            print("❌ SHA512ChecksumService: Failed to calculate SHA512 for \(fileURL.lastPathComponent)")
            return nil
        }
        
        print("✅ SHA512ChecksumService: Calculated SHA512 for \(datasetIdentifier):")
        print("   Full checksum: \(sha512)")
        print("   First 20 chars: \(String(sha512.prefix(20)))...")
        print("   Last 20 chars: ...\(String(sha512.suffix(20)))")
        
        localChecksums[datasetIdentifier] = sha512
        persistLocalChecksums()
        print("💾 SHA512ChecksumService: Stored SHA512 checksum for \(datasetIdentifier)")
        return sha512
    }
    
    /// Retrieves the stored local SHA512 checksum for a dataset
    public func getLocalChecksum(for datasetIdentifier: String) -> String? {
        return localChecksums[datasetIdentifier]
    }
    
    /// Remove a local checksum
    public func removeLocalChecksum(for datasetIdentifier: String) {
        localChecksums.removeValue(forKey: datasetIdentifier)
        persistLocalChecksums()
        print("🗑️ SHA512ChecksumService: Removed checksum for \(datasetIdentifier)")
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
            print("💾 SHA512ChecksumService: Loaded \(decodedChecksums.count) local checksums from disk.")
        } catch {
            print("❌ SHA512ChecksumService: Error loading persisted local checksums: \(error)")
        }
    }
    
    private func persistLocalChecksums() {
        do {
            let data = try JSONEncoder().encode(localChecksums)
            try data.write(to: persistenceURL, options: [.atomicWrite])
            print("💾 SHA512ChecksumService: Persisted \(localChecksums.count) local checksums to disk.")
        } catch {
            print("❌ SHA512ChecksumService: Error persisting local checksums: \(error)")
        }
    }
}
