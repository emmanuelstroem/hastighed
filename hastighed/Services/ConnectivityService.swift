import Foundation
import Network
import SwiftUI

public protocol NetworkPathMonitoring: AnyObject {
    var currentPath: NWPath { get }
    var pathUpdateHandler: (@Sendable (NWPath) -> Void)? { get set }
    func start(queue: DispatchQueue)
    func cancel()
}

extension NWPathMonitor: NetworkPathMonitoring {}

public final class ConnectivityService: @unchecked Sendable {
    public static let shared = ConnectivityService()
    private let monitor: NetworkPathMonitoring
    private let queue = DispatchQueue(label: "connectivity.monitor")
    private var observers: [UUID: (ConnectivityStatus) -> Void] = [:]
    private var lastStatus: ConnectivityStatus

    private init(monitor: NetworkPathMonitoring = NWPathMonitor()) {
        self.monitor = monitor
        self.lastStatus = ConnectivityStatus(usable: false, reason: .offline, networkType: .none)
        self.monitor.pathUpdateHandler = { [weak self] path in self?.handle(path) }
        self.monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }

    public func isInternetUsable() -> Bool { lastStatus.usable }
    public func currentNetworkType() -> NetworkType { lastStatus.networkType }

    public func onStatusChange(_ handler: @escaping (ConnectivityStatus) -> Void) -> UUID {
        let id = UUID()
        observers[id] = handler
        DispatchQueue.main.async { handler(self.lastStatus) }
        return id
    }

    public func removeObserver(_ id: UUID) { observers.removeValue(forKey: id) }

    private func handle(_ path: NWPath) {
        let status: ConnectivityStatus
        if path.status == .satisfied {
            let type: NetworkType
            if path.usesInterfaceType(.wifi) { type = .wifi }
            else if path.usesInterfaceType(.cellular) { type = .cellular }
            else { type = .other }
            status = ConnectivityStatus(usable: true, reason: .online, networkType: type)
        } else if path.isConstrained {
            status = ConnectivityStatus(usable: false, reason: .constrained, networkType: .none)
        } else {
            status = ConnectivityStatus(usable: false, reason: .offline, networkType: .none)
        }
        lastStatus = status
        notify(status)
    }

    private func notify(_ s: ConnectivityStatus) {
        DispatchQueue.main.async {
            for (_, cb) in self.observers { cb(s) }
        }
    }
}

public struct ConnectivityServiceKey: EnvironmentKey {
    public static let defaultValue: ConnectivityService = .shared
}

public extension EnvironmentValues {
    var connectivityService: ConnectivityService {
        get { self[ConnectivityServiceKey.self] }
        set { self[ConnectivityServiceKey.self] = newValue }
    }
}


