//
//  LadderVolumeView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import SwiftData
import UIKit

struct LadderVolumeView: View {
    let workout: Workout?
    let onWorkoutComplete: (Workout) -> Void
    
    @State private var currentLadder = 1
    @State private var currentRepInLadder = 1
    @State private var completedLadders: [Int] = [] // Array of max reps reached in each ladder
    @State private var isResting = false
    @State private var currentLadderReps: [Int] = [] // Track individual reps in current ladder
    @State private var manuallyCompleted = false // Track if user manually completed rest
    @State private var isCurrentSetConfirmed = false // Track if current set is locked in
    @State private var displayLadder = 1 // What ladder to show in progress view
    
    private let totalLadders = 5
    private let restTime = 30 // 30 seconds
    
    // NEW: Computed property for current ladder's completed rep count
    private var currentLadderCompletedReps: Int {
        currentLadderReps.count
    }
    
    private var nextRepText: String {
        if isCurrentSetConfirmed {
            if currentLadder >= totalLadders {
                return "Done!"
            } else {
                return "1 Rep"
            }
        } else {
            return "\(currentRepInLadder) Rep\(currentRepInLadder == 1 ? "" : "s")"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // UPDATED: Pass completed reps count instead of next rep number
            SetProgressView(
                totalSets: totalLadders,
                completedSets: completedLadders,
                currentReps: isCurrentSetConfirmed ? nil : currentLadderCompletedReps
            )
            .padding(.top, 24)
            .padding(.horizontal, 20)
            
            if !isResting{
                Spacer()
            }
            
            if currentLadder <= totalLadders {
                if isResting {
                    // Rest phase between individual reps
                    VStack(spacing: 40) {
                        HStack() {
                                
                            Text("Next:")
                                .largeSecondaryTextStyle()
                            Text(nextRepText)
                                .font(.system(size: 64, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        // 30-second timer with improved UI - centered horizontally
                        HStack {
                            Spacer()
                            SimpleCountdownTimer(initialTime: restTime, showFastForward: true) {
                                // Timer completed - handle based on set confirmation state
                                if !manuallyCompleted {
                                    if isCurrentSetConfirmed {
                                        // Set is locked in, advance to next ladder
                                        completeLadder()
                                    } else {
                                        // Set not confirmed, just end rest
                                        withAnimation {
                                            isResting = false
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: 320)
                            Spacer()
                        }
                        
                        // Set Complete / Undo Set Complete buttons - only if user has made progress
                        if currentLadderReps.count > 0 {
                            if isCurrentSetConfirmed {
                                Button(action: undoSetComplete) {
                                    Text("Undo Set Complete")
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 12)
                                        .background(.orange)
                                        .clipShape(Capsule())

                                }
                            } else {
                                Button(action: completeSet) {
                                    Text("Set Complete")
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 12)
                                        .background(.green)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        // Skip Rest button (DEBUG only, controlled by feature flag)
                        #if DEBUG
                        if FeatureFlags.hideFeature {
                            Button(action: completeRest) {
                                Text("Skip Rest")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 12)
                                    .background(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                        #endif
                    }
                } else {
                    // Active rep phase (matching third image layout)
                    VStack(spacing: 40) {
                        VStack(spacing: 12) {
                            Text("\(currentRepInLadder) Rep\(currentRepInLadder == 1 ? "" : "s")")
                                .largePrimaryTextStyle()
            
                            
                            VStack(spacing: 20) {
                                
                                
                                Button(action: completeCurrentRep) {
                                    Text("Rep Complete")
                                        .largePrimaryButtonTextStyle()
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
        .onAppear {
            // Keep screen awake during entire workout
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            // Re-enable screen sleep when view disappears
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    private func completeCurrentRep() {
        // Record the completed rep
        currentLadderReps.append(currentRepInLadder)
        
        // Save individual rep to workout
        if let workout = workout {
            workout.sets.append(1)
        }
        
        HapticManager.shared.success()
        
        // Reset manual completion flag and move to rest phase
        manuallyCompleted = false
        
        // Move to rest phase, then next rep
        withAnimation {
            isResting = true
            currentRepInLadder += 1
        }
        
        // Note: Ladder completion is now handled by the "Set Complete" button during rest
    }
    
    private func completeRest() {
        // User manually completed rest period or timer finished
        HapticManager.shared.success()
        manuallyCompleted = true
        
        // If current set is confirmed, advance to next ladder
        if isCurrentSetConfirmed {
            completeLadder()
        } else {
            withAnimation {
                isResting = false
            }
        }
    }
    
    private func completeSet() {
        // User locks in the current ladder's results
        HapticManager.shared.success()
        
        // Save the max reps for this ladder
        let maxReps = currentLadderReps.count
        completedLadders.append(maxReps)
        
        // Mark set as confirmed and advance display ladder
        withAnimation {
            isCurrentSetConfirmed = true
            displayLadder = min(currentLadder + 1, totalLadders + 1)
        }
        
        // If we're not in rest phase, immediately advance to next ladder
        // Otherwise, wait for timer to complete which will call completeLadder()
        if !isResting {
            completeLadder()
        }
        // Note: If isResting is true, the timer completion handler will call completeLadder()
    }
    
    private func undoSetComplete() {
        // User reverts the set confirmation
        HapticManager.shared.error()
        
        // Remove the last saved set
        if !completedLadders.isEmpty {
            completedLadders.removeLast()
        }
        
        // Revert confirmation state and display ladder
        withAnimation {
            isCurrentSetConfirmed = false
            displayLadder = currentLadder
        }
    }
    
    private func completeLadder() {
        // Advance to next ladder after confirming set
        HapticManager.shared.success()
        
        if currentLadder < totalLadders {
            // Move to next ladder
            withAnimation {
                currentLadder += 1
                displayLadder = currentLadder
                currentRepInLadder = 1
                currentLadderReps = []
                isResting = false
                manuallyCompleted = false
                isCurrentSetConfirmed = false
            }
        } else {
            // All ladders complete
            withAnimation {
                currentLadder += 1
                displayLadder = currentLadder
                isCurrentSetConfirmed = false
                manuallyCompleted = false
            }
        }
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
    .modelContainer(for: [Workout.self], inMemory: true)
}
