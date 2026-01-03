//
//  SubMaxVolumeWatchView.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import SwiftUI

struct SubMaxVolumeWatchView: View {
    let workout: Workout?
    let onWorkoutComplete: (Workout) -> Void
    
    @State private var currentSet = 1
    @State private var completedSets: [Int] = []
    @State private var isResting = false
    @State private var showNumberWheel = false
    @State private var liveSelectedReps = 0
    @State private var showSetCompleteButton = true
    
    private let totalSets = 10
    private let restTime = 60 // 1 minute
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 8) {
                if isResting {
                    // Rest phase layout: "Next:" text in the middle
                    // TimerWithSetsView will handle timer overlay and SetProgress at bottom
                    if showNumberWheel {
                        VStack(spacing: 4) {
                            NumberWheelWatch(
                                selectedValue: $liveSelectedReps,
                                minValue: 1,
                                maxValue: maxRepsForCurrentSet()
                            )
                        }
                    } else {
                        Text("Next: Submax")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Active set phase - no SetProgress here, it's in TimerWithSetsView                    
                    if currentSet <= totalSets {
                        VStack(spacing: 16) {
                            if currentSet == 1 {
                                Text("Sub-Max")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("50% of max reps")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(maxRepsForCurrentSet()) Reps")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("or form breakdown")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if showSetCompleteButton {
                                Button(action: completeCurrentSet) {
                                    Text("Set Complete")
                                        .font(.headline)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                            // Number wheel only shown after "Set Complete" is clicked
                            if showNumberWheel && !showSetCompleteButton {
                                VStack(spacing: 8) {
                                    NumberWheelWatch(
                                        selectedValue: $liveSelectedReps,
                                        minValue: 0,
                                        maxValue: maxRepsForCurrentSet()
                                    )
                                    
                                    // For final set, show completion button when reps are selected
                                    if currentSet == totalSets && liveSelectedReps > 0 {
                                        Button(action: completeFinalSet) {
                                            Text("Complete Workout")
                                                .font(.headline)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.green)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isResting)
            .animation(.easeInOut(duration: 0.3), value: showNumberWheel)
            .animation(.easeInOut(duration: 0.3), value: showSetCompleteButton)
            .animation(.easeInOut(duration: 0.3), value: currentSet)
            
            // TimerWithSetsView - always visible
            // Timer counts down when resting, SetProgress always shown at bottom
            TimerWithSetsView(
                initialTime: restTime,
                totalSets: totalSets,
                completedSets: completedSets,
                isTimerActive: isResting
            ) {
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
                    HapticManagerWatch.shared.error()
                }
            }
            .zIndex(1000) // Ensure it's on top
        }
    }
    
    private func completeCurrentSet() {
        let startingReps: Int
        if currentSet == 1 {
            startingReps = 1
        } else {
            startingReps = maxRepsForCurrentSet()
        }
        
        withAnimation {
            showSetCompleteButton = false
            showNumberWheel = true
            liveSelectedReps = startingReps
        }
        
        HapticManagerWatch.shared.success()
        
        if currentSet < totalSets {
            withAnimation {
                isResting = true
            }
        }
    }
    
    private func saveCurrentSet() {
        guard let workout = workout else { return }
        workout.sets.append(liveSelectedReps)
        completedSets.append(liveSelectedReps)
    }
    
    private func completeFinalSet() {
        saveCurrentSet()
        HapticManagerWatch.shared.success()
        
        withAnimation {
            currentSet += 1
            showNumberWheel = false
        }
        
        if let workout = workout {
            onWorkoutComplete(workout)
        }
    }
    
    private func maxRepsForCurrentSet() -> Int {
        if currentSet == 1 {
            return 20
        } else {
            let previousSetIndex = currentSet - 2
            if previousSetIndex >= 0 && previousSetIndex < completedSets.count {
                return max(completedSets[previousSetIndex], 1)
            }
            return 20
        }
    }
}

#Preview {
    let workout = Workout(type: .subMaxVolume)
    
    return SubMaxVolumeWatchView(workout: workout) { _ in
        print("Workout complete!")
    }
    .padding()
}

