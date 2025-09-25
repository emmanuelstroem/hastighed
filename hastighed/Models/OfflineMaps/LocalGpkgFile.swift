import Foundation

public struct LocalGpkgFile: Equatable, Hashable {
    public let datasetIdentifier: String
    public let localFilePath: String
    public let localFileSizeByteCount: Int64
    public let lastUpdatedAt: Date
    public let integrityStateDescription: String
    public let shouldPersistAcrossUpdates: Bool

    public init(
        datasetIdentifier: String,
        localFilePath: String,
        localFileSizeByteCount: Int64,
        lastUpdatedAt: Date,
        integrityStateDescription: String,
        shouldPersistAcrossUpdates: Bool = true
    ) {
        self.datasetIdentifier = datasetIdentifier
        self.localFilePath = localFilePath
        self.localFileSizeByteCount = localFileSizeByteCount
        self.lastUpdatedAt = lastUpdatedAt
        self.integrityStateDescription = integrityStateDescription
        self.shouldPersistAcrossUpdates = shouldPersistAcrossUpdates
    }
}


