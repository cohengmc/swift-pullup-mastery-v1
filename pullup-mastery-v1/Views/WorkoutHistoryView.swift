//
//  WorkoutHistoryView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if workouts.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Summary stats
                            WorkoutStatsCard(workouts: workouts)
                                .padding(.horizontal)
                            
                            // Workout list
                            ForEach(workouts) { workout in
                                WorkoutHistoryCard(workout: workout)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Clear All History", role: .destructive) {
                            clearAllWorkouts()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func clearAllWorkouts() {
        do {
            for workout in workouts {
                modelContext.delete(workout)
            }
            try modelContext.save()
        } catch {
            print("Error clearing workouts: \(error)")
        }
    }
}

struct WorkoutStatsCard: View {
    let workouts: [Workout]
    
    private var completedWorkouts: [Workout] {
        workouts.filter { !$0.sets.isEmpty }
    }
    
    private var totalReps: Int {
        completedWorkouts.reduce(0) { $0 + $1.totalReps }
    }
    
    private var averageRepsPerWorkout: Double {
        guard !completedWorkouts.isEmpty else { return 0 }
        return Double(totalReps) / Double(completedWorkouts.count)
    }
    
    private var workoutsByType: [WorkoutType: Int] {
        var counts: [WorkoutType: Int] = [:]
        for workout in completedWorkouts {
            counts[workout.type, default: 0] += 1
        }
        return counts
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
            
            // Main stats
            HStack(spacing: 20) {
                StatItem(
                    title: "Total Workouts",
                    value: "\(completedWorkouts.count)",
                    color: .blue
                )
                
                StatItem(
                    title: "Total Reps",
                    value: "\(totalReps)",
                    color: .green
                )
                
                StatItem(
                    title: "Avg/Workout",
                    value: String(format: "%.1f", averageRepsPerWorkout),
                    color: .orange
                )
            }
            
            // Workout type breakdown
            if !workoutsByType.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Workout Types")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(WorkoutType.allCases, id: \.self) { type in
                        if let count = workoutsByType[type], count > 0 {
                            HStack {
                                Text(type.rawValue)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text("\(count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WorkoutHistoryCard: View {
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.type.rawValue)
                        .font(.headline)
                    
                    Text(workout.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !workout.sets.isEmpty {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                }
            }
            
            // Stats
            HStack(spacing: 20) {
                Label("\(workout.completedSets) sets", systemImage: "list.number")
                    .font(.caption)
                
                Label("\(workout.totalReps) reps", systemImage: "number")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            // Rep breakdown
            if !workout.sets.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps per set:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(Array(workout.sets.enumerated()), id: \.offset) { index, reps in
                            Text("\(reps)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Notes section removed - notes property no longer exists
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive) {
                showingDeleteAlert = true
            }
        }
        .alert("Delete Workout", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
        } message: {
            Text("Are you sure you want to delete this workout? This action cannot be undone.")
        }
    }
    
    private func deleteWorkout() {
        withAnimation {
            modelContext.delete(workout)
            do {
                try modelContext.save()
            } catch {
                print("Error deleting workout: \(error)")
            }
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Workouts Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete your first workout to start tracking your progress!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    WorkoutHistoryView()
        .modelContainer(for: [Workout.self], inMemory: true)
}
