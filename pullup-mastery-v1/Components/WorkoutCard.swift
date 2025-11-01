//
//  WorkoutCard.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/31/25.
//

import SwiftUI
import SwiftData

struct WorkoutCard: View {
    let workout: Workout
    let isLastWorkout: Bool
    
    init(workout: Workout, isLastWorkout: Bool = false) {
        self.workout = workout
        self.isLastWorkout = isLastWorkout
    }
    
    private var workoutColor: Color {
        switch workout.type {
        case .maxDay:
            return .orange
        case .subMaxVolume:
            return .blue
        case .ladderVolume:
            return .green
        }
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    
                    if isLastWorkout {
                        Text("Last Workout")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(workout.type.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(workout.totalReps) Total Reps", systemImage: "number.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
            }
            
            // Rep breakdown
            if !workout.sets.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rep Breakdown:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        let maxReps = workout.sets.max() ?? 1
                        let minReps = workout.sets.min() ?? 1
                        // Use a higher minimum opacity to provide padding (0.33 for larger ranges, 0.5 for smaller)
                        let range = maxReps - minReps
                        let minOpacity: Double = range == 1 ? 0.5 : 0.33
                        
                        ForEach(Array(workout.sets.enumerated()), id: \.offset) { index, reps in
                            let opacity: Double = {
                                if maxReps == minReps {
                                    return 0.7
                                }
                                // Scale opacity linearly from minOpacity (for min reps) to 1.0 (for max reps)
                                let normalized = Double(reps - minReps) / Double(maxReps - minReps)
                                return minOpacity + (0.7 - minOpacity) * normalized
                            }()
                            
                            Text("\(reps)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(workoutColor.opacity(opacity))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
        }
        .padding()
        .background(workoutColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(workoutColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)

    }
}


// MARK: - Preview Helpers
private enum WorkoutSummaryPreviewData {
    static var sampleWorkout: Workout = {
        let w = Workout(type: .subMaxVolume)
        w.sets = [6, 6, 5,5,5,5,4,4,4,4]
        return w
    }()
}

#Preview {
    WorkoutCard(workout: WorkoutSummaryPreviewData.sampleWorkout)
    .modelContainer(for: [Workout.self], inMemory: true)
}

