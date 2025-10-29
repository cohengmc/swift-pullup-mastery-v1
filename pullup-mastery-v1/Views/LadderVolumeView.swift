//
//  LadderVolumeView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import SwiftData

struct LadderVolumeView: View {
    let workout: Workout?
    let onWorkoutComplete: (Workout) -> Void
    
    @State private var currentLadder = 1
    @State private var currentRepInLadder = 1
    @State private var completedLadders: [Int] = [] // Array of max reps reached in each ladder
    @State private var isResting = false
    @State private var currentLadderReps: [Int] = [] // Track individual reps in current ladder
    @State private var manuallyCompleted = false // Track if user manually completed rest
    
    private let totalLadders = 5
    private let restTime = 30 // 30 seconds
    
    var body: some View {
        VStack(spacing: 0) {
            // Set progress at top with improved spacing
            SetProgressView(
                currentLadder: currentLadder,
                totalLadders: totalLadders,
                completedLadders: completedLadders,
                currentRepInLadder: currentRepInLadder
            )
            .padding(.top, 24)
            .padding(.horizontal, 20)
            
            Spacer()
            
            if currentLadder <= totalLadders {
                if isResting {
                    // Rest phase between individual reps
                    VStack(spacing: 40) {
                        VStack(spacing: 12) {
                            Text("Rest")
                                .font(.system(size: 72, weight: .thin))
                                .foregroundColor(.blue)
                            
                            Text("Next: \(currentRepInLadder + 1) Rep\(currentRepInLadder + 1 == 1 ? "" : "s")")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        // 30-second timer with improved UI
                        SimpleCountdownTimer(initialTime: restTime, showFastForward: true) {
                            // Timer completed - advance automatically if not manually completed
                            if !manuallyCompleted {
                                withAnimation {
                                    currentRepInLadder += 1
                                    isResting = false
                                }
                            }
                        }
                        
                        Button(action: completeLadder) {
                            Text("Set Complete")
                                .font(.system(size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 12)
                                .background(.green)
                                .clipShape(Capsule())
                        }
                    }
                } else {
                    // Active rep phase (matching third image layout)
                    VStack(spacing: 40) {
                        VStack(spacing: 12) {
                            Text("\(currentRepInLadder) Rep\(currentRepInLadder == 1 ? "" : "s")")
                                .font(.system(size: 100, weight: .thin))
                                .foregroundColor(.blue)
            
                            
                            VStack(spacing: 20) {
                                
                                
                                Button(action: completeCurrentRep) {
                                    Text("Rep Complete")
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 12)
                                        .background(.blue)
                                        .clipShape(Capsule())
                                }
                                
                                
                            }
                            

                        }
                    }
                }
            } else {
                // Workout complete
                LadderCompleteCard(
                    completedLadders: completedLadders,
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
        .animation(.easeInOut(duration: 0.3), value: currentLadder)
        .animation(.easeInOut(duration: 0.3), value: currentRepInLadder)
    }
    
    private func completeCurrentRep() {
        // Record the completed rep
        currentLadderReps.append(currentRepInLadder)
        
        // Save individual rep to workout
        if let workout = workout {
            let repNumber = workout.sets.count + 1
            let newSet = WorkoutSet(setNumber: repNumber, reps: 1, restTime: restTime)
            workout.sets.append(newSet)
        }
        
        HapticManager.shared.success()
        
        // Reset manual completion flag and move to rest phase
        manuallyCompleted = false
        
        // Move to rest phase, then next rep
        withAnimation {
            isResting = true
        }
        
        // Check if ladder is complete (when user can't complete next rep target)
        // For now, let's assume they complete up to 10 reps max per ladder
        if currentRepInLadder > 10 {
            completeLadder()
        }
    }
    
    private func completeRest() {
        // User manually completed rest period
        HapticManager.shared.success()
        manuallyCompleted = true
        
        withAnimation {
            currentRepInLadder += 1
            isResting = false
        }
    }
    
    private func completeLadder() {
        // User is finishing the current ladder
        HapticManager.shared.success()
        
        // Calculate max reps for this ladder based on completed rep levels
        let maxReps = max(1, currentLadderReps.count)
        completedLadders.append(maxReps)
        
        if currentLadder < totalLadders {
            // Move to next ladder
            withAnimation {
                currentLadder += 1
                currentRepInLadder = 1
                currentLadderReps = []
                isResting = false
                manuallyCompleted = false
            }
        } else {
            // All ladders complete
            withAnimation {
                currentLadder += 1
                manuallyCompleted = false
            }
        }
    }
}

struct LadderInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.green)
                
                Text("Ladder Volume")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text("5 ascending ladders with 30 second rest")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("How it works:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Start with 1 rep, rest 30s, then 2 reps, rest 30s, etc.")
                        .font(.caption)
                    Text("• Continue until you can't complete a set")
                        .font(.caption)
                    Text("• Start next ladder with 1 rep")
                        .font(.caption)
                    Text("• Complete 5 total ladders")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct LadderSetView: View {
    let ladderNumber: Int
    let currentRep: Int
    let onSetResult: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Current ladder and rep info
            VStack(spacing: 8) {
                Text("Set \(ladderNumber)/5")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Set of \(currentRep)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            // Instructions
            VStack(spacing: 12) {
                Text("Can you complete \(currentRep) pull-up\(currentRep == 1 ? "" : "s") with good form?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("Be honest - only say yes if you can maintain proper form throughout the entire set.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Result buttons
            HStack(spacing: 20) {
                Button(action: { onSetResult(false) }) {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                        Text("Couldn't Complete")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: { onSetResult(true) }) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                        Text("Completed Successfully")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Ladder visualization
            LadderVisualization(currentRep: currentRep)
        }
        .padding()
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct LadderVisualization: View {
    let currentRep: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Ladder Progress:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                ForEach(1...currentRep, id: \.self) { rep in
                    Circle()
                        .fill(rep == currentRep ? .green : .green.opacity(0.6))
                        .frame(width: rep == currentRep ? 16 : 12, height: rep == currentRep ? 16 : 12)
                        .overlay(
                            Text("\(rep)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
                
                if currentRep < 10 {
                    ForEach((currentRep + 1)...min(currentRep + 3, 10), id: \.self) { rep in
                        Circle()
                            .stroke(.gray.opacity(0.5), lineWidth: 1)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Text("\(rep)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            )
                    }
                }
            }
        }
    }
}

struct LadderCompleteCard: View {
    let completedLadders: [Int]
    let onFinish: () -> Void
    
    private var totalReps: Int {
        completedLadders.reduce(0) { total, maxRep in
            // For each ladder, sum 1+2+3+...+maxRep
            total + (1...maxRep).reduce(0, +)
        }
    }
    
    private var averageMaxRep: Double {
        guard !completedLadders.isEmpty else { return 0 }
        return Double(completedLadders.reduce(0, +)) / Double(completedLadders.count)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Ladder Volume Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Text("Performance Summary")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    VStack {
                        Text("\(completedLadders.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Ladders")
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
                        Text(String(format: "%.1f", averageMaxRep))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("Avg Max")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Ladder breakdown
                if !completedLadders.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ladder Max Reps:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            ForEach(0..<completedLadders.count, id: \.self) { index in
                                Text("\(completedLadders[index])")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.green.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
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
    let workout = Workout(type: .ladderVolume)
    
    return NavigationView {
        LadderVolumeView(workout: workout) { _ in
            print("Workout complete!")
        }
    }
    .modelContainer(for: [Workout.self, WorkoutSet.self], inMemory: true)
}
