//
//  MaxDayView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import SwiftData

struct MaxDayView: View {
    let workout: Workout?
    let onWorkoutComplete: (Workout) -> Void
    
    @State private var currentSet = 1
    @State private var currentReps = 0
    @State private var completedSets: [WorkoutSet] = []
    @State private var isResting = false
    @State private var showNumberWheel = false
    @State private var liveSelectedReps = 0 // Real-time number wheel selection
    @State private var showSetCompleteButton = true // Controls when to show "Set Complete" button
    
    private let totalSets = 3
    private let restTime = 300 // 5 minutes
    
    var body: some View {
        VStack(spacing: 0) {
            // Set progress at top
            MaxDaySetProgress(
                currentSet: currentSet,
                totalSets: totalSets,
                completedSets: completedSets,
                currentReps: isResting ? nil : currentReps,
                liveReps: showNumberWheel ? liveSelectedReps : nil
            )
            .padding(.top, 20)
            .padding(.horizontal)
            
            Spacer()
            
            if currentSet <= totalSets {
                if isResting {
                    // Rest phase with new layout: timer center, number wheel + text side-by-side at bottom
                    VStack(spacing: 30) {
                        // Large central timer
                        SimpleCountdownTimer(initialTime: restTime, showFastForward: true) {
                            // Timer finished - save current set and move to next set
                            saveCurrentSet()
                            
                            withAnimation {
                                isResting = false
                                showNumberWheel = false
                                showSetCompleteButton = true
                                currentSet += 1
                                liveSelectedReps = 0
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
//                                Text("Rest")
//                                    .font(.system(size: 64, weight: .ultraLight))
//                                    .foregroundColor(.blue)
                                
                                Text("Next:")
//                                    .font(.title)
                                    .font(.system(size: 32, weight: .ultraLight))
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                                
                                Text("Max Reps")
//                                    .font(.title)
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
                    // Active set phase
                    VStack(spacing: 40) {
                        VStack(spacing: 8) {
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
                                Text("Next: 5 Minute Rest")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                        }
                        
                        // Number wheel only shown after "Set Complete" is clicked
                        if showNumberWheel && !showSetCompleteButton {
                            NumberWheel(selectedValue: $liveSelectedReps, minValue: 0, maxValue: maxRepsForCurrentSet())
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                }
            } else {
                // Workout complete
                WorkoutCompleteCard {
                    if let workout = workout {
                        onWorkoutComplete(workout)
                    }
                }
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.5), value: isResting)
        .animation(.easeInOut(duration: 0.3), value: showNumberWheel)
        .animation(.easeInOut(duration: 0.3), value: showSetCompleteButton)
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
        let newSet = WorkoutSet(setNumber: currentSet, reps: liveSelectedReps)
        workout.sets.append(newSet)
        completedSets.append(newSet)
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

struct MaxDaySetProgress: View {
    let currentSet: Int
    let totalSets: Int
    let completedSets: [WorkoutSet]
    let currentReps: Int?
    let liveReps: Int? // New parameter for real-time rep updates from number wheel
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(1...totalSets, id: \.self) { setNumber in
                VStack(spacing: 4) {
                    Text("Set \(setNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(backgroundColorForSet(setNumber))
                            .frame(width: 60, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(borderColorForSet(setNumber), lineWidth: 2)
                            )
                        
                        Text(textForSet(setNumber))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(textColorForSet(setNumber))
                    }
                }
            }
        }
    }
    
    private func backgroundColorForSet(_ setNumber: Int) -> Color {
        if setNumber < currentSet {
            return .blue.opacity(0.2)
        } else if setNumber == currentSet {
            return .blue.opacity(0.2)
        } else {
            return .red.opacity(0.2)
        }
    }
    
    private func borderColorForSet(_ setNumber: Int) -> Color {
        if setNumber < currentSet {
            return .blue
        } else if setNumber == currentSet {
            return .blue
        } else {
            return .red
        }
    }
    
    private func textColorForSet(_ setNumber: Int) -> Color {
        if setNumber < currentSet {
            return .blue
        } else if setNumber == currentSet {
            return .blue
        } else {
            return .red
        }
    }
    
    private func textForSet(_ setNumber: Int) -> String {
        if setNumber < currentSet {
            // Completed set - show reps
            if let completedSet = completedSets.first(where: { $0.setNumber == setNumber }) {
                return String(format: "%02d", completedSet.reps)
            }
            return "00"
        } else if setNumber == currentSet {
            // Current set - prioritize live reps from number wheel
            if let liveReps = liveReps, liveReps > 0 {
                return String(format: "%02d", liveReps)
            } else if let reps = currentReps, reps > 0 {
                return String(format: "%02d", reps)
            } else {
                return "↓"
            }
        } else {
            // Future set
            return "-"
        }
    }
}

struct WorkoutCompleteCard: View {
    let onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                
                Text("Workout Complete!")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(.green)
                
                Text("Excellent work! You've completed all 3 sets.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
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
    let workout = Workout(type: .maxDay)
    
    return NavigationView {
        MaxDayView(workout: workout) { _ in
            print("Workout complete!")
        }
    }
    .modelContainer(for: [Workout.self, WorkoutSet.self], inMemory: true)
}
