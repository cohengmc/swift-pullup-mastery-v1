//
//  pullupMastersyHelper_WatchApp.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import SwiftUI
import SwiftData

@main
struct pullupMastersyHelper_Watch_Watch_AppApp: App {
    init() {
        print("⌚ [Watch] App initializing...")
        // Initialize WatchConnectivity on app launch
        print("⌚ [Watch] Initializing WatchConnectivityManagerWatch...")
        _ = WatchConnectivityManagerWatch.shared
        print("⌚ [Watch] WatchConnectivityManagerWatch initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(SharedModelContainerWatch.create())
    }
}
