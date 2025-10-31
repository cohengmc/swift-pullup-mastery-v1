//
//  WorkoutView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    let workoutType: WorkoutType
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentWorkout: Workout?
    @State private var showingCompletionView = false
    @State private var showingExitAlert = false
    
    var body: some View {
        Group {
            if showingCompletionView, let workout = currentWorkout {
                // Show summary view when workout is complete
                WorkoutSummaryView(workout: workout) {
                    // Pop all the way back to HomeView
                    // First dismiss() pops WorkoutSummaryView back to WorkoutView
                    // Then onDismiss (this closure) dismisses WorkoutView back to HomeView
                    dismiss()
                }
            } else {
                // Show active workout view
                Group {
                    switch workoutType {
                    case .maxDay:
                        MaxDayView(
                            workout: currentWorkout,
                            onWorkoutComplete: handleWorkoutComplete
                        )
                    case .subMaxVolume:
                        SubMaxVolumeView(
                            workout: currentWorkout,
                            onWorkoutComplete: handleWorkoutComplete
                        )
                    case .ladderVolume:
                        LadderVolumeView(
                            workout: currentWorkout,
                            onWorkoutComplete: handleWorkoutComplete
                        )
                    }
                }
                .navigationTitle(workoutType.rawValue)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            if isWorkoutIncomplete() {
                                showingExitAlert = true
                            } else {
                                dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left").fontWeight(.heavy)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if currentWorkout == nil {
                createNewWorkout()
            }
        }
        .confirmationDialog("Do you want to exit workout?", isPresented: $showingExitAlert, titleVisibility: .visible) {
            Button("Yes, exit workout", role: .destructive) {
                exitWorkout()
            }
            Button("No, finish workout", role: .cancel) {
                // Stay on workout view - do nothing
            }
        } message: {
            Text("Workout data will be lost")
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
            showingCompletionView = true
        } catch {
            print("Error saving completed workout: \(error)")
        }
    }
    
    private func isWorkoutIncomplete() -> Bool {
        guard let workout = currentWorkout else { return true }
        // Workout is incomplete if it has no sets or doesn't have the expected number of sets
        return workout.sets.isEmpty || workout.sets.count < workout.type.maxSets
    }
    
    private func exitWorkout() {
        // Delete the incomplete workout from the model context
        if let workout = currentWorkout {
            modelContext.delete(workout)
            do {
                try modelContext.save()
            } catch {
                print("Error deleting workout: \(error)")
            }
        }
        dismiss()
    }
}

#Preview {
    NavigationView {
        WorkoutView(workoutType: .maxDay)
    }
    .modelContainer(for: [Workout.self], inMemory: true)
}
