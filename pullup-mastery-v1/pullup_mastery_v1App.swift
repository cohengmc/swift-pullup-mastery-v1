//
//  pullup_mastery_v1App.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import SwiftData

@main
struct pullup_mastery_v1App: App {
    init() {
        print("📱 [Phone] App initializing...")
        // Initialize WatchConnectivity on app launch
        print("📱 [Phone] Initializing WatchConnectivityManager...")
        _ = WatchConnectivityManager.shared
        print("📱 [Phone] WatchConnectivityManager initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(SharedModelContainer.create())
    }
}
