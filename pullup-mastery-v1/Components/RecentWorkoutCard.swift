//
//  RecentWorkoutCard.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/31/25.
//

import SwiftUI
import SwiftData

struct RecentWorkoutCard: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Last Workout")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(workout.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.type.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        Label("\(workout.sets[0]) reps in first set", systemImage: "1.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Label("\(workout.totalReps) Total Reps", systemImage: "number.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                if !workout.sets.isEmpty {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
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
    RecentWorkoutCard(workout: WorkoutSummaryPreviewData.sampleWorkout)
    .modelContainer(for: [Workout.self], inMemory: true)
}
