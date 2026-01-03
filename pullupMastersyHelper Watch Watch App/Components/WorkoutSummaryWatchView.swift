//
//  WorkoutSummaryWatchView.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import SwiftUI

struct WorkoutSummaryWatchView: View {
    let workout: Workout
    let onDismiss: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header with completion icon
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("Workout Complete!")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(workout.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                
                // Key Stats
                VStack(spacing: 8) {
                    // Total Reps - Large and prominent
                    VStack(spacing: 4) {
                        Text("\(workout.totalReps)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Total Reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
                    
                    // Sets and Date
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("\(workout.completedSets)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Sets")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        
                        VStack(spacing: 4) {
                            Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Text("Date")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 8)
                
                // Set Details
                if !workout.sets.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Set Details")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                        
                        // Scrollable list of sets
                        ForEach(Array(workout.sets.enumerated()), id: \.offset) { index, reps in
                            HStack {
                                Text("Set \(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(reps) reps")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                
                // Done Button
                Button(action: onDismiss) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 8)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
        }
    }
}

#Preview {
    let sampleWorkout = Workout(type: .maxDay)
    sampleWorkout.sets = [8, 7, 6]
    
    return WorkoutSummaryWatchView(workout: sampleWorkout) {
        print("Dismissed")
    }
    .padding()
}

