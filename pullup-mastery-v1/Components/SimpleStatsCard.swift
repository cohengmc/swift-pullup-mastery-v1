//
//  SimpleStatsCard.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/31/25.
//

import SwiftUI
import SwiftData

struct SimpleStatsCard: View {
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
            HStack(){
                Text("Stats")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: WorkoutHistoryView()) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
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
                

        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
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

#Preview {
    // Create sample workouts for testing
    let workout1 = Workout(type: .maxDay, date: Date().addingTimeInterval(-86400 * 2)) // 2 days ago
    workout1.sets = [8, 7, 6]
    
    let workout2 = Workout(type: .subMaxVolume, date: Date().addingTimeInterval(-86400)) // 1 day ago
    workout2.sets = [5, 5, 5, 5, 5, 4, 4, 4, 4, 4]
    
    let workout3 = Workout(type: .ladderVolume, date: Date()) // Today
    workout3.sets = [5, 4, 3]
    
    let workout4 = Workout(type: .maxDay, date: Date().addingTimeInterval(-86400 * 3)) // 3 days ago
    workout4.sets = [9, 8, 7]
    
    // Create workouts array
    let workouts = [workout1, workout2, workout3, workout4]
    
    return SimpleStatsCard(workouts: workouts)
        .modelContainer(for: [Workout.self], inMemory: true)
}
