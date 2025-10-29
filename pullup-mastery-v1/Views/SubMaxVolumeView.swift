//
//  SubMaxVolumeView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import SwiftData

struct SubMaxVolumeView: View {
    let workout: Workout?
    let onWorkoutComplete: (Workout) -> Void
    
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    
    @State private var currentSet = 1
    @State private var currentReps = 0
    @State private var completedSets: [WorkoutSet] = []
    @State private var isRestingBetweenSets = false
    @State private var showNumberWheel = false
    @State private var showSetCompleteButton = true
    @State private var targetReps = 5 // Default, will be calculated from max day
    
    private let totalSets = 10
    private let restTime = 60 // 1 minute
    
    var maxDayWorkouts: [Workout] {
        allWorkouts.filter { $0.type == .maxDay && $0.completed }
    }
    
    var calculatedTargetReps: Int {
        guard let lastMaxDay = maxDayWorkouts.first,
              let maxSet = lastMaxDay.sets.max(by: { $0.reps < $1.reps }) else {
            return 5 // Default fallback
        }
        return max(1, maxSet.reps / 2) // 50% of max, minimum 1
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Set progress at top - using horizontal layout for better consistency
            SetProgressView(
                currentSet: currentSet,
                totalSets: totalSets,
                completedSets: completedSets,
                currentReps: isRestingBetweenSets ? nil : currentReps,
                liveReps: showNumberWheel ? currentReps : nil
            )
            .padding(.top, 20)
            .padding(.horizontal)
            
            Spacer()
            
            if currentSet <= totalSets {
                if isRestingBetweenSets {
                    // Rest phase with new layout: timer center, number wheel + text side-by-side at bottom
                    VStack(spacing: 30) {
                        // Large central timer (60 seconds)
                        SimpleCountdownTimer(initialTime: restTime, showFastForward: true) {
                            // Timer finished - save current set and move to next set
                            // Only save if user has selected reps (no auto-defaults)
                            if currentReps > 0 {
                                saveCurrentSet()
                                
                                withAnimation {
                                    isRestingBetweenSets = false
                                    showNumberWheel = false
                                    showSetCompleteButton = true
                                    currentSet += 1
                                    currentReps = targetReps
                                }
                            } else {
                                // User hasn't selected reps - give feedback
                                HapticManager.shared.error()
                            }
                        }
                        .padding(.horizontal, 50)
                        
                        // Bottom section: number wheel (left) + rest text (right)
                        HStack(alignment: .center, spacing: 40) {
                            // Left side: Number wheel (compact)
                            if showNumberWheel {
                                NumberWheel(selectedValue: $currentReps, minValue: 0, maxValue: max(20, targetReps + 10))
                                    .transition(.opacity.combined(with: .scale))
                                    .frame(maxWidth: 140) // Constrain width for better balance
                            }
                            
                            // Right side: Rest text (prominent)
                            VStack(spacing: 12) {
                                Text("Rest")
                                    .font(.system(size: 64, weight: .ultraLight))
                                    .foregroundColor(.blue)
                                
                                Text("Next: \(targetReps) Reps")
                                    .font(.title)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
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
                                Text("50%")
                                    .font(.system(size: 100, weight: .thin))
                                    .foregroundColor(.blue)
                                
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
                                
                                if currentSet < totalSets && !isRestingBetweenSets {
                                    VStack(spacing: 8) {
                                        Text("Target: \(targetReps) reps")
                                            .font(.title3)
                                            .fontWeight(.medium)
                                            .foregroundColor(.orange)
                                        
                                        if let lastMaxDay = maxDayWorkouts.first {
                                            Text("Based on your last Max Day (\(lastMaxDay.date, style: .date))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Text("Next: 1 Minute Rest")
                                            .font(.title3)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            
                            // Number wheel only shown after "Set Complete" is clicked
                            if showNumberWheel && !showSetCompleteButton {
                                VStack(spacing: 20) {
                                    NumberWheel(selectedValue: $currentReps, minValue: 0, maxValue: max(20, targetReps + 10))
                                        .transition(.opacity.combined(with: .scale))
                                    
                                    // For final set, show completion button when reps are selected
                                    if currentSet == totalSets && currentReps > 0 {
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
                    targetReps: targetReps,
                    onFinish: {
                        if let workout = workout {
                            onWorkoutComplete(workout)
                        }
                    }
                )
            }
            
            Spacer()
        }
        .onAppear {
            targetReps = calculatedTargetReps
            currentReps = targetReps
        }
        .animation(.easeInOut(duration: 0.5), value: isRestingBetweenSets)
        .animation(.easeInOut(duration: 0.3), value: showNumberWheel)
        .animation(.easeInOut(duration: 0.3), value: showSetCompleteButton)
        .animation(.easeInOut(duration: 0.3), value: currentSet)
    }
    
    private func completeCurrentSet() {
        // Hide "Set Complete" button and show number wheel immediately
        withAnimation {
            showSetCompleteButton = false
            showNumberWheel = true
        }
        
        HapticManager.shared.success()
        
        // Start rest immediately if not the last set, timer will start automatically
        if currentSet < totalSets {
            withAnimation {
                isRestingBetweenSets = true
            }
        } else {
            // Last set - just show number wheel, no timer
        }
    }
    
    private func saveCurrentSet() {
        guard let workout = workout else { return }
        
        let newSet = WorkoutSet(setNumber: currentSet, reps: currentReps, restTime: restTime)
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
}

struct SubMaxInfoCard: View {
    let targetReps: Int
    let lastMaxDay: Workout?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speedometer")
                    .foregroundColor(.orange)
                
                Text("Sub Max Volume")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text("10 sets at 50% max with 1 minute rest")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Target Reps per Set:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(targetReps)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                if let lastMaxDay = lastMaxDay {
                    Text("Based on your last Max Day (\(lastMaxDay.date, style: .date))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Complete a Max Day workout first to calculate your target")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Text("Instructions: Aim to complete all 10 sets at the target reps. If you can't maintain the target, do as many as possible with good form.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SubMaxSetView: View {
    let setNumber: Int
    let targetReps: Int
    @Binding var selectedReps: Int
    let onSetComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Set indicator
            VStack(spacing: 8) {
                Text("Set \(setNumber)/10")
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack {
                    Text("Target:")
                    Text("\(targetReps)")
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("reps")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            // Rep selector
            VStack(spacing: 16) {
                Text("How many reps did you complete?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                NumberWheel(selectedValue: $selectedReps, minValue: 0, maxValue: max(20, targetReps + 10))
            }
            
            // Progress indicator
            if selectedReps > 0 {
                HStack {
                    if selectedReps >= targetReps {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Target achieved!")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.orange)
                        Text("\(targetReps - selectedReps) below target")
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption)
                .fontWeight(.medium)
            }
            
            // Complete button
            Button(action: onSetComplete) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete Set")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(.orange)
                .clipShape(Capsule())
            }
            .disabled(selectedReps == 0)
        }
        .padding()
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SubMaxCompleteCard: View {
    let completedSets: [WorkoutSet]
    let targetReps: Int
    let onFinish: () -> Void
    
    private var totalReps: Int {
        completedSets.reduce(0) { $0 + $1.reps }
    }
    
    private var targetAchieved: Int {
        completedSets.filter { $0.reps >= targetReps }.count
    }
    
    private var targetTotal: Int {
        completedSets.count * targetReps
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Sub Max Volume Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                Text("Performance Summary")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    VStack {
                        Text("\(targetAchieved)/10")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("Sets at Target")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(totalReps)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Total Reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(Int((Double(totalReps) / Double(targetTotal)) * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("of Target")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button(action: onFinish) {
                HStack {
                    Image(systemName: "trophy.fill")
                    Text("Finish Workout")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(.green)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
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
