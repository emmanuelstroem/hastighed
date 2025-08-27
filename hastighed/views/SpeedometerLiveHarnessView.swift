//
//  SpeedometerLiveSimulator.swift
//  hastighed
//
//  Created by Emmanuel on 27/08/2025.
//

import SwiftUI

struct SpeedometerLiveHarnessView: View {
    @State private var speed: Double = 40
    @State private var limit: Double? = 50
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                SpeedometerView(
                    speedKmh: speed,
                    maxSpeedKmh: 201,
                    size: 260,
                    batteryLevel: 0,
                    speedLimitKmh: limit
                )
                VStack(spacing: 16) {
                    HStack {
                        Text("Speed: \(Int(speed)) km/h").foregroundColor(.white)
                        Slider(value: $speed, in: 0...140, step: 1)
                    }
                    HStack {
                        let binding = Binding<Double>(
                            get: { limit ?? 0 },
                            set: { limit = ($0 <= 0 ? nil : $0) }
                        )
                        Text("Limit: \(limit.map { Int($0) } ?? 0) km/h").foregroundColor(.white)
                        Slider(value: binding, in: 0...130, step: 5)
                    }
                }
                .padding(.horizontal)
            }
            .foregroundColor(.white)
        }
    }
}

#Preview {
    SpeedometerLiveHarnessView()
}
