//
//  hastighedApp.swift
//  hastighed
//
//  Created by Emmanuel on 18/09/2025.
//

import SwiftUI
import Network

@main
struct hastighedApp: App {
    private let connectivityService = ConnectivityService.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.connectivityService, connectivityService)
        }
    }
}
