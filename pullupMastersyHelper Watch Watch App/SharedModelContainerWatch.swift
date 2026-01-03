//
//  SharedModelContainerWatch.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import Foundation
import SwiftData

class SharedModelContainerWatch {
    static let appGroupIdentifier = "group.geoffcohen.pullup-mastery"
    private static let migrationCompletedKey = "AppGroupToDefaultMigrationCompleted"
    
    static func create() -> ModelContainer {
        let schema = Schema([
            Workout.self,
        ])
        
        print("⌚ [Watch] Creating ModelContainer (using default SwiftData location)")
        
        // Check if migration from App Groups is needed (one-time)
        let migrationCompleted = UserDefaults.standard.bool(forKey: migrationCompletedKey)
        if !migrationCompleted {
            print("📦 [Watch] Checking for App Group data to migrate...")
            migrateFromAppGroupIfNeeded(schema: schema)
            UserDefaults.standard.set(true, forKey: migrationCompletedKey)
        }
        
        // Use default SwiftData location (device-specific)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ [Watch] Created ModelContainer (default location)")
            return container
        } catch {
            print("❌ [Watch] Failed to create ModelContainer: \(error)")
            if let nsError = error as NSError? {
                print("❌ [Watch] Error domain: \(nsError.domain), code: \(nsError.code)")
                print("❌ [Watch] Error userInfo: \(nsError.userInfo)")
            }
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    /// One-time migration from App Group location to default SwiftData location
    private static func migrateFromAppGroupIfNeeded(schema: Schema) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            print("📦 [Watch] No App Group container found, skipping migration")
            return
        }
        
        let appGroupDatabaseURL = containerURL.appendingPathComponent("WorkoutData.sqlite")
        
        guard FileManager.default.fileExists(atPath: appGroupDatabaseURL.path) else {
            print("📦 [Watch] No App Group database found, skipping migration")
            return
        }
        
        print("📦 [Watch] Found App Group database, migrating to default location...")
        
        // Create default container
        guard let defaultContainer = try? ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]) else {
            print("❌ [Watch] Failed to create default container for migration")
            return
        }
        
        let defaultContext = ModelContext(defaultContainer)
        
        // Try to read from App Group location
        let appGroupConfiguration = ModelConfiguration(
            schema: schema,
            url: appGroupDatabaseURL,
            allowsSave: false,
            cloudKitDatabase: .none
        )
        
        guard let appGroupContainer = try? ModelContainer(for: schema, configurations: [appGroupConfiguration]) else {
            print("❌ [Watch] Failed to open App Group container for migration")
            return
        }
        
        let appGroupContext = ModelContext(appGroupContainer)
        let descriptor = FetchDescriptor<Workout>()
        
        guard let workouts = try? appGroupContext.fetch(descriptor), !workouts.isEmpty else {
            print("📦 [Watch] No workouts found in App Group database, skipping migration")
            return
        }
        
        print("📦 [Watch] Migrating \(workouts.count) workouts from App Group to default location...")
        
        // Copy workouts to default location
        for workout in workouts {
            let newWorkout = Workout(type: workout.type, date: workout.date)
            newWorkout.id = workout.id
            newWorkout.sets = workout.sets
            defaultContext.insert(newWorkout)
        }
        
        do {
            try defaultContext.save()
            print("✅ [Watch] Successfully migrated \(workouts.count) workouts")
        } catch {
            print("❌ [Watch] Error saving migrated workouts: \(error)")
        }
    }
}

