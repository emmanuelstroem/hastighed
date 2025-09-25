import Foundation

public enum NetworkType {
    case wifi
    case cellular
    case other
    case none
}

public enum ConnectivityReason {
    case online
    case offline
    case constrained
}

public struct ConnectivityStatus {
    public let usable: Bool
    public let reason: ConnectivityReason
    public let networkType: NetworkType
}


