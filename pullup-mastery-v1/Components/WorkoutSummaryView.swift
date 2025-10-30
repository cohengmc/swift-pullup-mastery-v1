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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Celebration header
                    VStack(spacing: 16) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.yellow)
                        
                        Text("Workout Complete!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                    }
                    
                    
                    RepBreakdownChart(
                        title: workout.type.rawValue,
                        data: workout.sets,
                        totalReps: workout.totalReps
                    )
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: onDismiss) {
                            Text("Done")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.blue)
                                .clipShape(Capsule())
                        }
                        
                        Button("Share Results") {
                            shareWorkoutResults()
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }
    
    private func shareWorkoutResults() {
        // TODO: Implement sharing functionality
        print("Share workout results")
    }
}


// MARK: - Preview Helpers
private enum WorkoutSummaryPreviewData {
    static var sampleWorkout: Workout = {
        let w = Workout(type: .ladderVolume)
        w.sets = [5, 5, 4,4,4]
        return w
    }()
}

#Preview {
    WorkoutSummaryView(workout: WorkoutSummaryPreviewData.sampleWorkout) {
        print("Dismissed")
    }
    .modelContainer(for: [Workout.self], inMemory: true)
}
