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
    @State private var selectedWorkout: Workout?
    @State private var showingWorkoutSheet = false
    
    var body: some View {
        NavigationView {
            Group {
                if workouts.isEmpty {
                    EmptyHistoryView()
                } else {
                    VStack(spacing: 0) {
                        // Summary stats (fixed at top)
                        WorkoutStatsCard(workouts: workouts)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        // Workout list (scrollable)
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(Array(workouts.enumerated()), id: \.element.id) { index, workout in
                                    WorkoutCard(workout: workout, isLastWorkout: index == 0)
                                        .onTapGesture {
                                            selectedWorkout = workout
                                            showingWorkoutSheet = true
                                        }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingWorkoutSheet) {
                if let workout = selectedWorkout {
                    NavigationView {
                        WorkoutSummaryView(workout: workout, showDeleteButton: true) {
                            showingWorkoutSheet = false
                            selectedWorkout = nil
                        }
                    }
                }
            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
//                
////                ToolbarItem(placement: .navigationBarTrailing) {
////                    Menu {
////                        Button("Clear All History", role: .destructive) {
////                            clearAllWorkouts()
////                        }
////                    } label: {
////                        Image(systemName: "ellipsis.circle")
////                    }
////                }
//            }
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
    
    private var averageWorkoutsPerWeek: Double {
        guard !completedWorkouts.isEmpty else { return 0 }
        
        // Find the date range
        let sortedWorkouts = completedWorkouts.sorted { $0.date < $1.date }
        guard let firstDate = sortedWorkouts.first?.date,
              let lastDate = sortedWorkouts.last?.date else { return 0 }
        
        // Calculate the number of weeks
        let timeInterval = lastDate.timeIntervalSince(firstDate)
        let days = timeInterval / (24 * 60 * 60)
        let weeks = max(1, days / 7) // At least 1 week to avoid division by zero
        
        return Double(completedWorkouts.count) / weeks
    }
    
    private var totalWeeks: Int {
        guard !completedWorkouts.isEmpty else { return 0 }
        
        // Get unique weeks that contain workouts
        let calendar = Calendar.current
        var uniqueWeeks = Set<String>()
        
        for workout in completedWorkouts {
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.date)
            if let year = components.yearForWeekOfYear, let week = components.weekOfYear {
                uniqueWeeks.insert("\(year)-\(week)")
            }
        }
        
        return uniqueWeeks.count
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
            Text("Stats")
                .font(.headline)
            
            // Main stats
            HStack(alignment: .top, spacing: 10) {
                    StatItem(
                        title: "Workouts",
                        value: "\(completedWorkouts.count)",
                        color: .blue
                    )
                    
                    StatItem(
                        title: "Total Reps",
                        value: "\(totalReps)",
                        color: .green
                    )
                    
                    StatItem(
                        title: "Workouts/Week",
                        value: String(format: "%.1f", averageWorkoutsPerWeek),
                        color: .orange
                    )
                    StatItem(
                        title: "Weeks",
                        value: "\(totalWeeks)",
                        color: .red
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


//        .swipeActions(edge: .trailing) {
//            Button("Delete", role: .destructive) {
//                showingDeleteAlert = true
//            }
//        }
//        .alert("Delete Workout", isPresented: $showingDeleteAlert) {
//            Button("Cancel", role: .cancel) { }
//            Button("Delete", role: .destructive) {
//                deleteWorkout()
//            }
//        } message: {
//            Text("Are you sure you want to delete this workout? This action cannot be undone.")
//        }
    
//    private func deleteWorkout() {
//        withAnimation {
//            modelContext.delete(workout)
//            do {
//                try modelContext.save()
//            } catch {
//                print("Error deleting workout: \(error)")
//            }
//        }
//    }

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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)
    let context = container.mainContext
    
    // Create sample workouts for testing
    let workout1 = Workout(type: .maxDay, date: Date().addingTimeInterval(-86400 * 4)) // 4 days ago
    workout1.sets = [8, 7, 6]
    
    let workout2 = Workout(type: .subMaxVolume, date: Date().addingTimeInterval(-86400*2)) // 2 day ago
    workout2.sets = [5, 5, 5, 5, 5, 4, 4, 4, 4, 4]
    
    let workout3 = Workout(type: .ladderVolume, date: Date()) // Today
    workout3.sets = [5, 4,4,4, 3]
    
    let workout4 = Workout(type: .maxDay, date: Date().addingTimeInterval(-86400 * 8)) // 8 days ago
    workout4.sets = [9, 8, 7]
    
    // Insert workouts into context
    context.insert(workout1)
    context.insert(workout2)
    context.insert(workout3)
    context.insert(workout4)
    
    return WorkoutHistoryView()
        .modelContainer(container)
}
