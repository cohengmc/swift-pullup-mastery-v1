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
            if showingCompletion, let workout = currentWorkout {
                // Workout summary view
                WorkoutSummaryWatchView(workout: workout) {
                    dismiss()
                }
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
        Task {
            await handleWorkoutCompleteAsync(workout)
        }
    }
    
    private func handleWorkoutCompleteAsync(_ workout: Workout) async {
        print("✅ [Watch] Workout completed: \(workout.type.rawValue)")
        print("✅ [Watch] Workout ID: \(workout.id)")
        print("✅ [Watch] Workout date: \(workout.date)")
        print("✅ [Watch] Total reps: \(workout.totalReps), Sets: \(workout.sets.count)")
        print("✅ [Watch] Sets array: \(workout.sets)")
        
        do {
            // Save workout to local SwiftData database (watch's own database)
            try modelContext.save()
            print("✅ [Watch] Workout saved to local model context")
            
            // Process pending changes to ensure write is complete
            modelContext.processPendingChanges()
            print("✅ [Watch] Processed pending changes")
            
            // Send workout data to phone via WatchConnectivity
            print("📤 [Watch] Sending workout data to phone via WatchConnectivity...")
            print("📤 [Watch] Workout details: ID=\(workout.id), Type=\(workout.type.rawValue), Date=\(workout.date)")
            WatchConnectivityManagerWatch.shared.sendWorkoutData(workout)
            
            withAnimation {
                showingCompletion = true
            }
        } catch {
            print("❌ [Watch] Error saving completed workout: \(error)")
            if let nsError = error as NSError? {
                print("❌ [Watch] Error domain: \(nsError.domain), code: \(nsError.code)")
                print("❌ [Watch] Error userInfo: \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutViewWatch(workoutType: .maxDay)
    }
    .modelContainer(for: [Workout.self], inMemory: true)
}

