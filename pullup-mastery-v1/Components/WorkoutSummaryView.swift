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
                        
                        Text(workout.type.rawValue)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Performance summary
                    WorkoutPerformanceCard(workout: workout)
                    
                    // Rep breakdown chart
                    WorkoutChart(workout: workout)
                    
                    // Insights and analysis
                    WorkoutInsightsCard(workout: workout)
                    
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

struct WorkoutPerformanceCard: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Summary")
                .font(.headline)
            
            HStack(spacing: 20) {
                PerformanceMetric(
                    title: "Sets",
                    value: "\(workout.completedSets)",
                    subtitle: "completed",
                    color: .blue
                )
                
                PerformanceMetric(
                    title: "Total Reps",
                    value: "\(workout.totalReps)",
                    subtitle: "performed",
                    color: .green
                )
                
                if !workout.sets.isEmpty {
                    let avgReps = Double(workout.totalReps) / Double(workout.completedSets)
                    PerformanceMetric(
                        title: "Avg/Set",
                        value: String(format: "%.1f", avgReps),
                        subtitle: "reps",
                        color: .orange
                    )
                }
            }
            
            // Workout-specific metrics
            if workout.type == .subMaxVolume {
                SubMaxMetrics(workout: workout)
            } else if workout.type == .ladderVolume {
                LadderMetrics(workout: workout)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct PerformanceMetric: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SubMaxMetrics: View {
    let workout: Workout
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    
    private var targetReps: Int {
        let maxDayWorkouts = allWorkouts.filter { $0.type == .maxDay && $0.completed }
        guard let lastMaxDay = maxDayWorkouts.first,
              let maxSet = lastMaxDay.sets.max(by: { $0.reps < $1.reps }) else {
            return 5
        }
        return max(1, maxSet.reps / 2)
    }
    
    private var setsAtTarget: Int {
        workout.sets.filter { $0.reps >= targetReps }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sub Max Analysis")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Text("Target: \(targetReps) reps per set")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(setsAtTarget)/\(workout.completedSets) sets hit target")
                    .font(.caption)
                    .foregroundColor(setsAtTarget >= workout.completedSets * 7 / 10 ? .green : .orange)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.blue)
                        .frame(width: geometry.size.width * CGFloat(setsAtTarget) / CGFloat(workout.completedSets), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct LadderMetrics: View {
    let workout: Workout
    
    private var ladderBreakdown: [Int] {
        // Calculate ladder breakdown from individual reps
        // This is simplified - in real implementation, we'd track ladders properly
        var ladders: [Int] = []
        var currentLadder = 0
        var repCount = 1
        
        for set in workout.sets {
            if set.reps == 1 {
                currentLadder += repCount
                repCount = 1
                ladders.append(currentLadder)
                currentLadder = 0
            } else {
                repCount += 1
            }
        }
        
        return ladders
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ladder Analysis")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Text("Ladders completed: \(ladderBreakdown.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !ladderBreakdown.isEmpty {
                    let avgMax = Double(ladderBreakdown.reduce(0, +)) / Double(ladderBreakdown.count)
                    Text("Avg max: \(String(format: "%.1f", avgMax))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
}

struct WorkoutChart: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rep Breakdown")
                .font(.headline)
            
            if !workout.sets.isEmpty {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(workout.sets.sorted { $0.setNumber < $1.setNumber }, id: \.id) { set in
                        VStack(spacing: 4) {
                            Text("\(set.reps)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.blue)
                                .frame(width: 24, height: max(8, CGFloat(set.reps) * 4))
                            
                            Text("\(set.setNumber)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                Text("No sets recorded")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct WorkoutInsightsCard: View {
    let workout: Workout
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    
    private var previousWorkouts: [Workout] {
        allWorkouts.filter { $0.type == workout.type && $0.completed && $0.date < workout.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                if let lastWorkout = previousWorkouts.first {
                    let improvement = workout.totalReps - lastWorkout.totalReps
                    HStack {
                        Image(systemName: improvement >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(improvement >= 0 ? .green : .red)
                        
                        Text("\(abs(improvement)) reps \(improvement >= 0 ? "more" : "fewer") than last \(workout.type.rawValue)")
                            .font(.caption)
                    }
                } else {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        
                        Text("First \(workout.type.rawValue) workout! Great job starting your journey.")
                            .font(.caption)
                    }
                }
                
                // Workout-specific insights
                if workout.type == .maxDay {
                    MaxDayInsights(workout: workout)
                } else if workout.type == .subMaxVolume {
                    SubMaxInsights(workout: workout, allWorkouts: allWorkouts)
                } else if workout.type == .ladderVolume {
                    LadderInsights(workout: workout)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct MaxDayInsights: View {
    let workout: Workout
    
    var body: some View {
        if let bestSet = workout.sets.max(by: { $0.reps < $1.reps }) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                
                Text("Your best set was \(bestSet.reps) reps (Set \(bestSet.setNumber))")
                    .font(.caption)
            }
        }
    }
}

struct SubMaxInsights: View {
    let workout: Workout
    let allWorkouts: [Workout]
    
    var body: some View {
        let maxDayWorkouts = allWorkouts.filter { $0.type == .maxDay && $0.completed }
        if let lastMaxDay = maxDayWorkouts.first {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                
                Text("Based on your Max Day from \(lastMaxDay.date, style: .date)")
                    .font(.caption)
            }
        }
    }
}

struct LadderInsights: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundColor(.green)
            
            Text("Progressive training builds endurance and strength")
                .font(.caption)
        }
    }
}

#Preview {
    let workout = Workout(type: .maxDay)
    workout.sets = [
        WorkoutSet(setNumber: 1, reps: 8),
        WorkoutSet(setNumber: 2, reps: 7),
        WorkoutSet(setNumber: 3, reps: 6)
    ]
    workout.completed = true
    
    return WorkoutSummaryView(workout: workout) {
        print("Dismissed")
    }
    .modelContainer(for: [Workout.self, WorkoutSet.self], inMemory: true)
}
