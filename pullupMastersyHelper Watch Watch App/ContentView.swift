//
//  ContentView.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(WorkoutType.allCases, id: \.self) { workoutType in
                    NavigationLink(destination: WorkoutViewWatch(workoutType: workoutType)) {
                        WorkoutTypeRow(workoutType: workoutType)
                    }
                }
            }
            .navigationTitle("Workouts")
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutDataReceived"))) { notification in
                print("⌚ [Watch] Received WorkoutDataReceived notification")
                if let workout = notification.userInfo?["workout"] as? Workout {
                    print("⌚ [Watch] Saving workout to database: \(workout.id)")
                    modelContext.insert(workout)
                    do {
                        try modelContext.save()
                        print("✅ [Watch] Workout saved successfully")
                    } catch {
                        print("❌ [Watch] Error saving workout: \(error)")
                    }
                }
            }
        }
    }
}

struct WorkoutTypeRow: View {
    let workoutType: WorkoutType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workoutType.rawValue)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(workoutType.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Workout.self], inMemory: true)
}
