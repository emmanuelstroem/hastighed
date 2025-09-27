import Foundation

public struct DatasetListing: Codable, Equatable, Hashable {
    public let datasetIdentifier: String
    public let countryName: String
    public let versionLabel: String?
    public let expectedTotalByteCount: Int64?
    public let remoteResourceAddress: String
    public let lastUpdatedDateDescription: String?

    public init(
        datasetIdentifier: String,
        countryName: String,
        versionLabel: String? = nil,
        expectedTotalByteCount: Int64? = nil,
        remoteResourceAddress: String,
        lastUpdatedDateDescription: String? = nil
    ) {
        self.datasetIdentifier = datasetIdentifier
        self.countryName = countryName
        self.versionLabel = versionLabel
        self.expectedTotalByteCount = expectedTotalByteCount
        self.remoteResourceAddress = remoteResourceAddress
        self.lastUpdatedDateDescription = lastUpdatedDateDescription
    }
    
    public nonisolated static let allDatasets: [DatasetListing] = [
        DatasetListing(
            datasetIdentifier: "denmark",
            countryName: "Denmark",
            expectedTotalByteCount: nil,
            remoteResourceAddress: "https://hastighed.stillestorm.dk/denmark.gpkg"
        ),
        DatasetListing(
            datasetIdentifier: "liechtenstein",
            countryName: "Liechtenstein",
            expectedTotalByteCount: nil,
            remoteResourceAddress: "https://hastighed.stillestorm.dk/liechtenstein.gpkg"
        ),
        DatasetListing(
            datasetIdentifier: "sweden",
            countryName: "Sweden",
            expectedTotalByteCount: nil,
            remoteResourceAddress: "https://hastighed.stillestorm.dk/sweden.gpkg"
        )
    ]
}


