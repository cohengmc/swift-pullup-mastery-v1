//
//  WorkoutViewWatch.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import SwiftUI
import SwiftData

struct WorkoutViewWatch: View {
    let workoutType: WorkoutType
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentWorkout: Workout?
    @State private var showingCompletion = false
    
    var body: some View {
        Group {
            if showingCompletion {
                // Simple completion view
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Workout Complete!")
                        .font(.headline)
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                // Show active workout view
                Group {
                    switch workoutType {
                    case .maxDay:
                        MaxDayWatchView(
                            workout: currentWorkout,
                            onWorkoutComplete: handleWorkoutComplete
                        )
                    case .subMaxVolume:
                        SubMaxVolumeWatchView(
                            workout: currentWorkout,
                            onWorkoutComplete: handleWorkoutComplete
                        )
                    case .ladderVolume:
                        LadderVolumeWatchView(
                            workout: currentWorkout,
                            onWorkoutComplete: handleWorkoutComplete
                        )
                    }
                }
                .navigationTitle(workoutType.rawValue)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            if currentWorkout == nil && !showingCompletion {
                createNewWorkout()
            }
        }
        .onDisappear {
            if !showingCompletion {
                // User is exiting early - clean up
                if let workout = currentWorkout, workout.sets.isEmpty {
                    modelContext.delete(workout)
                    do {
                        try modelContext.save()
                    } catch {
                        print("Error deleting workout: \(error)")
                    }
                }
                currentWorkout = nil
            }
        }
    }
    
    private func createNewWorkout() {
        let workout = Workout(type: workoutType)
        modelContext.insert(workout)
        currentWorkout = workout
    }
    
    private func handleWorkoutComplete(_ workout: Workout) {
        do {
            try modelContext.save()
            withAnimation {
                showingCompletion = true
            }
        } catch {
            print("Error saving completed workout: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutViewWatch(workoutType: .maxDay)
    }
    .modelContainer(for: [Workout.self], inMemory: true)
}

