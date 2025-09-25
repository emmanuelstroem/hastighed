import Foundation

public struct DownloadPolicy: Equatable, Hashable {
    public var cellularConfirmationThresholdByteCount: Int64 = 50 * 1024 * 1024
    public var currentConnectivityTypeDescription: String = "offline" // "wifi" | "cellular" | "offline"

    public init() {}

    public func requiresUserConfirmationOnCellular(for expectedTotalByteCount: Int64?) -> Bool {
        guard currentConnectivityTypeDescription == "cellular", let expected = expectedTotalByteCount else { return false }
        return expected >= cellularConfirmationThresholdByteCount
    }
}


