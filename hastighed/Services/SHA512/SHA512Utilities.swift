import Foundation
import CryptoKit

/// Utilities for computing SHA512 checksums of local files
public struct SHA512Utilities {
    
    /// Calculate SHA512 checksum for a file at the given URL
    /// - Parameter url: The URL of the file to calculate checksum for
    /// - Returns: The SHA512 checksum as a hexadecimal string, or nil if calculation fails
    public static func calculateSHA512(forFileAt url: URL) -> String? {
        do {
            let data = try Data(contentsOf: url)
            return calculateSHA512(for: data)
        } catch {
            return nil
        }
    }
    
    /// Calculate SHA512 checksum for data
    /// - Parameter data: The data to calculate checksum for
    /// - Returns: The SHA512 checksum as a hexadecimal string
    public static func calculateSHA512(for data: Data) -> String {
        let digest = SHA512.hash(data: data)
        return digest.compactMap { String(format: "%02hhx", $0) }.joined()
    }
}

