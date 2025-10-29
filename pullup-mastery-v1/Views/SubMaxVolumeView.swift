//
//  SubMaxVolumeView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/29/25.
//

import SwiftUI
import SwiftData

struct SubMaxVolumeView: View {
    let workout: Workout?
    let onWorkoutComplete: (Workout) -> Void
    
    @State private var currentSet = 1
    @State private var currentReps = 0
    @State private var completedSets: [WorkoutSet] = []
    @State private var isResting = false
    @State private var showNumberWheel = false
    @State private var liveSelectedReps = 0 // Real-time number wheel selection
    @State private var showSetCompleteButton = true // Controls when to show "Set Complete" button
    
    private let totalSets = 10
    private let restTime = 60 // 1 minute
    
    var body: some View {
        VStack(spacing: 0) {
            // Set progress at top - automatically handles scrolling for 10 sets
            SetProgressView(
                totalSets: totalSets,
                completedSets: completedSets.map { $0.reps },
                currentReps: isResting ? (showNumberWheel ? liveSelectedReps : nil) : currentReps
            )
            .padding(.top, 20)
            .padding(.horizontal, 20)
            .frame(height: 100)
            
            Spacer()
            
            if currentSet <= totalSets {
                if isResting {
                    // Rest phase with new layout: timer center, number wheel + text side-by-side at bottom
                    VStack(spacing: 30) {
                        // Large central timer
                        SimpleCountdownTimer(initialTime: restTime, showFastForward: true) {
                            // Timer finished - save current set and move to next set
                            // Only save if user has selected reps (no auto-defaults)
                            if liveSelectedReps > 0 {
                                saveCurrentSet()
                                
                                withAnimation {
                                    isResting = false
                                    showNumberWheel = false
                                    showSetCompleteButton = true
                                    currentSet += 1
                                    liveSelectedReps = 0
                                }
                            } else {
                                // User hasn't selected reps - give feedback and keep timer at 1 second
                                HapticManager.shared.error()
                                // Note: This should rarely happen as user should select reps during rest
                            }
                        }
                        .padding(.horizontal, 50)
                        
                        // Bottom section: number wheel (left) + rest text (right)
                        HStack(alignment: .center, spacing: 40) {
                            // Left side: Number wheel (compact)
                            if showNumberWheel {
                                NumberWheel(selectedValue: $liveSelectedReps, minValue: 0, maxValue: maxRepsForCurrentSet())
                                    .transition(.opacity.combined(with: .scale))
                                    .frame(maxWidth: 140) // Constrain width for better balance
                            }
                            
                            // Right side: Rest text (prominent)
                            VStack(spacing: 12) {
                                Text("Next:")
                                    .font(.system(size: 32, weight: .ultraLight))
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                                
                                Text("Max Reps")
                                    .font(.system(size: 32, weight: .ultraLight))
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 24)
                    }
                } else {
                    // Active set phase - vertically centered
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 40) {
                            VStack(spacing: 16) {
                                Text("Max Reps")
                                    .font(.system(size: 72, weight: .thin))
                                    .foregroundColor(.blue)
                                
                                if showSetCompleteButton {
                                    Button(action: completeCurrentSet) {
                                        Text("Set Complete")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 32)
                                            .padding(.vertical, 12)
                                            .background(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                if currentSet < totalSets && !isResting {
                                    Text("Next: 1 Minute Rest")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                }
                            }
                            
                            // Number wheel only shown after "Set Complete" is clicked
                            if showNumberWheel && !showSetCompleteButton {
                                VStack(spacing: 20) {
                                    NumberWheel(selectedValue: $liveSelectedReps, minValue: 0, maxValue: maxRepsForCurrentSet())
                                        .transition(.opacity.combined(with: .scale))
                                    
                                    // For final set, show completion button when reps are selected
                                    if currentSet == totalSets && liveSelectedReps > 0 {
                                        Button(action: completeFinalSet) {
                                            Text("Complete Workout")
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 32)
                                                .padding(.vertical, 12)
                                                .background(.green)
                                                .clipShape(Capsule())
                                        }
                                        .transition(.opacity.combined(with: .scale))
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                }
            } else {
                // Workout complete
                SubMaxCompleteCard(
                    completedSets: completedSets,
                    onFinish: {
                        if let workout = workout {
                            onWorkoutComplete(workout)
                        }
                    }
                )
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.5), value: isResting)
        .animation(.easeInOut(duration: 0.3), value: showNumberWheel)
        .animation(.easeInOut(duration: 0.3), value: showSetCompleteButton)
        .animation(.easeInOut(duration: 0.3), value: currentSet)
    }
    
    private func completeCurrentSet() {
        // Hide "Set Complete" button and show number wheel immediately
        withAnimation {
            showSetCompleteButton = false
            showNumberWheel = true
            liveSelectedReps = 0 // Reset to 0 for rep input
        }
        
        HapticManager.shared.success()
        
        // Start rest immediately - timer will auto-start when it appears
        if currentSet < totalSets {
            withAnimation {
                isResting = true
            }
        } else {
            // Last set - just show number wheel, no timer
            // User can input reps and workout will complete when they're done
        }
    }
    
    private func saveCurrentSet() {
        guard let workout = workout else { return }
        
        // Save the set with reps selected on the number wheel
        let newSet = WorkoutSet(setNumber: currentSet, reps: liveSelectedReps, restTime: restTime)
        workout.sets.append(newSet)
        completedSets.append(newSet)
    }
    
    private func completeFinalSet() {
        // Save the final set and complete the workout
        saveCurrentSet()
        
        HapticManager.shared.success()
        
        withAnimation {
            currentSet += 1 // This will trigger the SubMaxCompleteCard
            showNumberWheel = false
        }
    }
    
    private func maxRepsForCurrentSet() -> Int {
        if currentSet == 1 {
            return 20 // First set can go up to 20 reps
        } else {
            // For subsequent sets, limit to previous set's completed reps
            if let previousSet = completedSets.first(where: { $0.setNumber == currentSet - 1 }) {
                return max(previousSet.reps, 1) // Ensure at least 1 rep is possible
            }
            return 20 // Fallback to 20 if previous set not found
        }
    }
}

// MARK: - Completion Card
struct SubMaxCompleteCard: View {
    let completedSets: [WorkoutSet]
    let onFinish: () -> Void
    
    private var totalReps: Int {
        completedSets.reduce(0) { $0 + $1.reps }
    }
    
    private var averageReps: Double {
        guard !completedSets.isEmpty else { return 0 }
        return Double(totalReps) / Double(completedSets.count)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                
                Text("Workout Complete!")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(.green)
                
                // Stats
                VStack(spacing: 12) {
                    HStack(spacing: 24) {
                        VStack {
                            Text("\(completedSets.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Sets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(totalReps)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Total Reps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text(String(format: "%.1f", averageReps))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("Avg Reps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Text("Excellent work on your volume training!")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            
            Button(action: onFinish) {
                Text("Finish Workout")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(.green)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 40)
    }
}

#Preview {
    let workout = Workout(type: .subMaxVolume)
    
    return NavigationView {
        SubMaxVolumeView(workout: workout) { _ in
            print("Workout complete!")
        }
    }
    .modelContainer(for: [Workout.self, WorkoutSet.self], inMemory: true)
}
