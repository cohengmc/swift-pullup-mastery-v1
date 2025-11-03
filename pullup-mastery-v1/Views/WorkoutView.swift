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
                
                // Celebration header
                VStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                    
                    Text("Workout Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                }
                
                // Show summary view when workout is complete
                WorkoutSummaryView(workout: workout, showDeleteButton: false) {
                    // Post notification before dismissing so HomeView can reset navigation
                    NotificationCenter.default.post(name: NSNotification.Name("WorkoutCompleted"), object: nil)
                    // Clear workout state and dismiss
                    currentWorkout = nil
                    showingCompletionView = false
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
            // Only create a new workout if we don't have one and we're not showing completion
            if currentWorkout == nil && !showingCompletionView {
                createNewWorkout()
            }
        }
        .onDisappear {
            // Only reset if we're not in completion view (i.e., user is exiting early)
            // If we're showing completion, we want to keep the state until user dismisses
            if !showingCompletionView {
                // User is exiting early - clean up
                if let workout = currentWorkout, workout.sets.isEmpty {
                    // Delete empty workout if user exits before completing
                    modelContext.delete(workout)
                    do {
                        try modelContext.save()
                    } catch {
                        print("Error deleting workout: \(error)")
                    }
                }
                currentWorkout = nil
                showingCompletionView = false
            }
        }
        .alert("Exit Workout", isPresented: $showingExitAlert) {
            Button("Stay", role: .cancel) { }
            Button("Exit Workout", role: .destructive) {
                exitWorkout()
            }
        } message: {
            Text("Are you sure you want to exit this workout? Data from this workout  will be lost.")
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
            // Show completion view - notification will be posted when user dismisses
            withAnimation {
                showingCompletionView = true
            }
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
