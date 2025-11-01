//
//  WorkoutSummaryView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    let workout: Workout
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    
    var body: some View {
            VStack(alignment: .center, spacing: 24) {
                
                RepBreakdownChart(
                    title: workout.type.rawValue,
                    data: workout.sets,
                    totalReps: workout.totalReps,
                    date: workout.date
                )
            
                
                // Actions
                HStack(spacing: 8) {
                    
                    Button(action: shareWorkoutResults) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                            .padding()
                            .background(.blue)
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        // Dismiss this view first (pops back to WorkoutView)
                        dismiss()
                        // Then call onDismiss to dismiss WorkoutView and return to HomeView
                        // Use async to ensure the first dismiss completes before the second
                        DispatchQueue.main.async {
                            onDismiss()
                        }
                    }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.blue)
                            .clipShape(Capsule())
                    }
                    
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .padding()
                            .background(.blue)
                            .clipShape(Circle())
                    }
                    
                    
                    
                }
                
            }
            .padding()
            .navigationTitle("Workout Complete")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showingEditSheet) {
                EditWorkoutView(workout: workout)
        }
    }
    
    private func shareWorkoutResults() {
        // TODO: Implement sharing functionality
        print("Share workout results")
    }
}

struct EditWorkoutView: View {
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var repValues: [Int] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    RepInputCard(repValues: $repValues, workoutType: workout.type, enableAutoPopulate: false)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle("Edit Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWorkout()
                    }
                }
            }
        }
        .onAppear {
            // Initialize repValues with current workout sets
            repValues = workout.sets
        }
    }
    
    private func saveWorkout() {
        // Update the workout's sets with the new values
        workout.sets = repValues
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("Error saving workout: \(error)")
        }
    }
}


// MARK: - Preview Helpers
private enum WorkoutSummaryPreviewData {
    static var sampleWorkout: Workout = {
        let w = Workout(type: .ladderVolume)
        w.sets = [6, 5, 4,4,4]
        return w
    }()
}

#Preview {
    WorkoutSummaryView(workout: WorkoutSummaryPreviewData.sampleWorkout) {
        print("Dismissed")
    }
    .modelContainer(for: [Workout.self], inMemory: true)
}
