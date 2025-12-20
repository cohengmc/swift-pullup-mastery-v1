//
//  SharedModelContainerWatch.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import Foundation
import SwiftData

class SharedModelContainerWatch {
    static func create() -> ModelContainer {
        let schema = Schema([
            Workout.self,
        ])
        
        // Use App Groups container for shared data
        let appGroupIdentifier = "group.geoffcohen.pullup-mastery"
        
        // Try to get App Group container
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        let databaseURL = containerURL?.appendingPathComponent("WorkoutData.sqlite")
        
        // Check if App Group database exists
        let appGroupDatabaseExists = databaseURL != nil && FileManager.default.fileExists(atPath: databaseURL!.path)
        
        // If App Group database doesn't exist, check default location for migration
        if !appGroupDatabaseExists {
            // Try to find data in default SwiftData location
            if let defaultContainer = try? ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]) {
                let context = ModelContext(defaultContainer)
                let descriptor = FetchDescriptor<Workout>()
                
                // Check if there's existing data in default location
                if let workouts = try? context.fetch(descriptor), !workouts.isEmpty {
                    // Data exists in old location - migrate it
                    if let containerURL = containerURL, let databaseURL = databaseURL {
                        // Create App Group container if it doesn't exist
                        try? FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
                        
                        // Create new container in App Group location
                        let newConfiguration = ModelConfiguration(
                            schema: schema,
                            url: databaseURL,
                            allowsSave: true,
                            cloudKitDatabase: .none
                        )
                        
                        if let newContainer = try? ModelContainer(for: schema, configurations: [newConfiguration]) {
                            let newContext = ModelContext(newContainer)
                            
                            // Copy all workouts to new location
                            for workout in workouts {
                                let newWorkout = Workout(type: workout.type, date: workout.date)
                                newWorkout.id = workout.id
                                newWorkout.sets = workout.sets
                                newContext.insert(newWorkout)
                            }
                            
                            // Save migrated data
                            try? newContext.save()
                            
                            // Return the new container with migrated data
                            return newContainer
                        }
                    }
                }
            }
        }
        
        // Use App Group location if available, otherwise fallback to default
        guard let containerURL = containerURL, let databaseURL = databaseURL else {
            // Fallback to default location if App Groups not available
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: databaseURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}

