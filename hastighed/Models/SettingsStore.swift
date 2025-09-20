import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage(AppStorageKeys.vehicleTopSpeed) var vehicleTopSpeed: Double = 180 { willSet { objectWillChange.send() } }
    @AppStorage(AppStorageKeys.isDebugOverlayEnabled) var isDebugOverlayEnabled: Bool = false { willSet { objectWillChange.send() } }
    @AppStorage(AppStorageKeys.showGauge) var showGauge: Bool = true { willSet { objectWillChange.send() } }
    @AppStorage(AppStorageKeys.showSpeedLimit) var showSpeedLimit: Bool = true { willSet { objectWillChange.send() } }
    @AppStorage(AppStorageKeys.showSpeedCameras) var showSpeedCameras: Bool = true { willSet { objectWillChange.send() } }
    @AppStorage(AppStorageKeys.showHazards) var showHazards: Bool = true { willSet { objectWillChange.send() } }
    // Battery saver removed

    var speedUnitLabel: String { AppConstants.speedUnitLabel }

    func displaySpeed(from kmh: Double) -> Double {
        return kmh
    }

    func displayLimit(from kmh: Double) -> Double { displaySpeed(from: kmh) }

    func convertToKmh(from displayed: Double) -> Double { displayed }
}
