//
//  ContentView.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
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
