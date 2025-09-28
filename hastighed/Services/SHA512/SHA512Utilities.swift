import Foundation
import CryptoKit

/// Utilities for computing SHA512 checksums of local files
public struct SHA512Utilities {
    
    /// Calculate SHA512 checksum for a file at the given URL
    /// - Parameter url: The URL of the file to calculate checksum for
    /// - Returns: The SHA512 checksum as a hexadecimal string, or nil if calculation fails
    public static func calculateSHA512(forFileAt url: URL) -> String? {
        let bufferSize = 1024 * 1024 // 1 MB buffer for efficient reading
        
        do {
            let file = try FileHandle(forReadingFrom: url)
            defer {
                file.closeFile()
            }
            
            var hasher = SHA512()
            
            while autoreleasepool(invoking: {
                let data = file.readData(ofLength: bufferSize)
                if data.count > 0 {
                    hasher.update(data: data)
                    return true
                } else {
                    return false
                }
            }) {}
            
            let digest = hasher.finalize()
            return digest.compactMap { String(format: "%02hhx", $0) }.joined()
            
        } catch {
            print("❌ SHA512Utilities: Failed to calculate SHA512 for file at \(url): \(error)")
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

