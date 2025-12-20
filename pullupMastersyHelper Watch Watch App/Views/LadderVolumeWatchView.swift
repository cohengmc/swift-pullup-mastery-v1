//
//  LadderVolumeWatchView.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import SwiftUI

struct LadderVolumeWatchView: View {
    let workout: Workout?
    let onWorkoutComplete: (Workout) -> Void
    
    @State private var currentLadder = 1
    @State private var currentRepInLadder = 1
    @State private var completedLadders: [Int] = []
    @State private var isResting = false
    @State private var currentLadderReps: [Int] = []
    @State private var manuallyCompleted = false
    @State private var isCurrentSetConfirmed = false
    
    private let totalLadders = 5
    private let restTime = 30 // 30 seconds
    
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
        VStack(spacing: 8) {
            // Set progress at top
            SetProgressWatchView(
                totalSets: totalLadders,
                completedSets: completedLadders,
                currentReps: isCurrentSetConfirmed ? nil : currentLadderCompletedReps
            )
            .padding(.top, 8)
            
            Spacer()
            
            if currentLadder <= totalLadders {
                if isResting {
                    // Rest phase
                    VStack(spacing: 12) {
                        Text("Next: \(nextRepText)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Timer
                        CountdownTimerWatchView(initialTime: restTime) {
                            if !manuallyCompleted {
                                if isCurrentSetConfirmed {
                                    completeLadder()
                                } else {
                                    withAnimation {
                                        isResting = false
                                    }
                                }
                            }
                        }
                        
                        // Set Complete / Undo Set Complete buttons
                        if currentLadderReps.count > 0 {
                            if isCurrentSetConfirmed {
                                Button(action: undoSetComplete) {
                                    Text("Undo Set Complete")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .tint(.orange)
                            } else {
                                Button(action: completeSet) {
                                    Text("Set Complete")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            }
                        }
                    }
                } else {
                    // Active rep phase
                    VStack(spacing: 16) {
                        Text("\(currentRepInLadder) Rep\(currentRepInLadder == 1 ? "" : "s")")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Button(action: completeCurrentRep) {
                            Text("Rep Complete")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: isResting)
        .animation(.easeInOut(duration: 0.3), value: currentLadder)
        .animation(.easeInOut(duration: 0.3), value: currentRepInLadder)
    }
    
    private func completeCurrentRep() {
        currentLadderReps.append(currentRepInLadder)
        HapticManagerWatch.shared.success()
        
        manuallyCompleted = false
        
        withAnimation {
            isResting = true
            currentRepInLadder += 1
        }
    }
    
    private func completeRest() {
        HapticManagerWatch.shared.success()
        manuallyCompleted = true
        
        if isCurrentSetConfirmed {
            completeLadder()
        } else {
            withAnimation {
                isResting = false
            }
        }
    }
    
    private func completeSet() {
        HapticManagerWatch.shared.success()
        
        let maxReps = currentLadderReps.count
        completedLadders.append(maxReps)
        
        if let workout = workout {
            workout.sets.append(maxReps)
        }
        
        withAnimation {
            isCurrentSetConfirmed = true
        }
        
        if !isResting {
            completeLadder()
        }
    }
    
    private func undoSetComplete() {
        HapticManagerWatch.shared.error()
        
        if !completedLadders.isEmpty {
            completedLadders.removeLast()
        }
        
        if let workout = workout, !workout.sets.isEmpty {
            workout.sets.removeLast()
        }
        
        withAnimation {
            isCurrentSetConfirmed = false
        }
    }
    
    private func completeLadder() {
        HapticManagerWatch.shared.success()
        
        if currentLadder < totalLadders {
            withAnimation {
                currentLadder += 1
                currentRepInLadder = 1
                currentLadderReps = []
                isResting = false
                manuallyCompleted = false
                isCurrentSetConfirmed = false
            }
        } else {
            withAnimation {
                currentLadder += 1
                isCurrentSetConfirmed = false
                manuallyCompleted = false
            }
            
            if let workout = workout {
                onWorkoutComplete(workout)
            }
        }
    }
}

#Preview {
    let workout = Workout(type: .ladderVolume)
    
    return LadderVolumeWatchView(workout: workout) { _ in
        print("Workout complete!")
    }
    .padding()
}

