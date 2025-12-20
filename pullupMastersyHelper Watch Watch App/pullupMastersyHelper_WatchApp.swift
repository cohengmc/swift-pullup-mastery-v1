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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(SharedModelContainerWatch.create())
    }
}
