import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("topSpeedKmh") var topSpeedKmh: Double = 180 { willSet { objectWillChange.send() } }
    @AppStorage("useImperialUnits") var useImperialUnits: Bool = false { willSet { objectWillChange.send() } }

    var speedUnitLabel: String { useImperialUnits ? "mph" : "km/h" }

    func displaySpeed(from kmh: Double) -> Double {
        if useImperialUnits { return kmh * 0.621371 } // km/h -> mph
        return kmh
    }

    func displayLimit(from kmh: Double) -> Double { displaySpeed(from: kmh) }

    func convertToKmh(from displayed: Double) -> Double { useImperialUnits ? displayed / 0.621371 : displayed }
}
