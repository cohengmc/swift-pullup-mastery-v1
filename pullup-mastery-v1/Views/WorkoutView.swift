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
    @State private var showingCompletionSheet = false
    
    var body: some View {
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
        .onAppear {
            createNewWorkout()
        }
        .sheet(isPresented: $showingCompletionSheet) {
            if let workout = currentWorkout {
                WorkoutSummaryView(workout: workout) {
                    dismiss()
                }
            }
        }
    }
    
    private func createNewWorkout() {
        let workout = Workout(type: workoutType)
        modelContext.insert(workout)
        currentWorkout = workout
    }
    
    private func handleWorkoutComplete(_ workout: Workout) {
        workout.completed = true
        do {
            try modelContext.save()
            showingCompletionSheet = true
        } catch {
            print("Error saving completed workout: \(error)")
        }
    }
}

struct WorkoutCompletionView: View {
    let workout: Workout
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Celebration
                VStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                    
                    Text("Workout Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Great job on your \(workout.type.rawValue) workout!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Workout summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Summary")
                        .font(.headline)
                    
                    WorkoutSummaryCard(workout: workout)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    Button("View History") {
                        // This would navigate to history, but for now just dismiss
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Done") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle("Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct WorkoutSummaryCard: View {
    let workout: Workout
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Total Sets", systemImage: "list.number")
                Spacer()
                Text("\(workout.completedSets)")
                    .fontWeight(.semibold)
            }
            
            HStack {
                Label("Total Reps", systemImage: "number")
                Spacer()
                Text("\(workout.totalReps)")
                    .fontWeight(.semibold)
            }
            
            if !workout.sets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reps per set:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        ForEach(workout.sets.sorted { $0.setNumber < $1.setNumber }, id: \.id) { set in
                            Text("\(set.reps)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            HStack {
                Label("Date", systemImage: "calendar")
                Spacer()
                Text(workout.date, style: .date)
                    .fontWeight(.semibold)
            }
        }
    }
}

#Preview {
    NavigationView {
        WorkoutView(workoutType: .maxDay)
    }
    .modelContainer(for: [Workout.self, WorkoutSet.self], inMemory: true)
}
