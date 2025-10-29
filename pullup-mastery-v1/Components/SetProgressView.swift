//
//  SetProgressView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI

struct SetProgressView: View {
    let currentSet: Int
    let totalSets: Int
    let completedSets: [WorkoutSet]
    let currentReps: Int?
    let liveReps: Int? // Real-time rep updates from number wheel
    
    // Ladder workout parameters (optional)
    let completedLadders: [Int]? // Array of max reps reached in each completed ladder
    let currentRepInLadder: Int?
    
    // Regular workout initializer
    init(currentSet: Int, totalSets: Int, completedSets: [WorkoutSet], currentReps: Int? = nil, liveReps: Int? = nil) {
        self.currentSet = currentSet
        self.totalSets = totalSets
        self.completedSets = completedSets
        self.currentReps = currentReps
        self.liveReps = liveReps
        self.completedLadders = nil
        self.currentRepInLadder = nil
    }
    
    // Ladder workout initializer
    init(currentLadder: Int, totalLadders: Int, completedLadders: [Int], currentRepInLadder: Int) {
        self.currentSet = currentLadder
        self.totalSets = totalLadders
        self.completedSets = []
        self.currentReps = nil
        self.liveReps = nil
        self.completedLadders = completedLadders
        self.currentRepInLadder = currentRepInLadder
    }
    
    private var isLadderMode: Bool {
        completedLadders != nil
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Set label - different for ladder mode
            if isLadderMode {
                HStack {
                    Text("Ladder \(currentSet)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            // Progress indicators
            HStack(spacing: isLadderMode ? 12 : 20) {
                ForEach(1...totalSets, id: \.self) { setNumber in
                    VStack(spacing: 4) {
                        if !isLadderMode {
                            Text("Set \(setNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
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
    }
    
    private func backgroundColorForSet(_ setNumber: Int) -> Color {
        if setNumber < currentSet {
            // Completed set - green background
            return .green.opacity(0.2)
        } else if setNumber == currentSet {
            // Current set - blue background
            return .blue.opacity(0.2)
        } else {
            // Future set - red background
            return .red.opacity(0.2)
        }
    }
    
    private func borderColorForSet(_ setNumber: Int) -> Color {
        if setNumber < currentSet {
            // Completed set - green border
            return .green
        } else if setNumber == currentSet {
            // Current set - blue border
            return .blue
        } else {
            // Future set - red border
            return .red
        }
    }
    
    private func textColorForSet(_ setNumber: Int) -> Color {
        if setNumber < currentSet {
            // Completed set - green text
            return .green
        } else if setNumber == currentSet {
            // Current set - blue text
            return .blue
        } else {
            // Future set - red text
            return .red
        }
    }
    
    private func textForSet(_ setNumber: Int) -> String {
        if isLadderMode {
            // Ladder mode logic
            if setNumber < currentSet {
                // Completed ladder - show max reps achieved
                if let completedLadders = completedLadders,
                   completedLadders.indices.contains(setNumber - 1) {
                    return String(format: "%02d", completedLadders[setNumber - 1])
                }
                return "00"
            } else if setNumber == currentSet {
                // Current ladder - show current rep being attempted or arrow if just starting
                if let currentRepInLadder = currentRepInLadder, currentRepInLadder > 1 {
                    return String(format: "%02d", currentRepInLadder)
                } else {
                    return "↓"
                }
            } else {
                // Future ladder
                return "-"
            }
        } else {
            // Regular workout mode logic
            if setNumber < currentSet {
                // Completed set - show checkmark
                return "✓"
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
}




#Preview {
    VStack(spacing: 20) {
        SetProgressView(
            currentSet: 2,
            totalSets: 3,
            completedSets: [
                WorkoutSet(setNumber: 1, reps: 8)
            ],
            currentReps: 6,
            liveReps: nil
        )
        
        SetProgressView(
            currentLadder: 3,
            totalLadders: 5,
            completedLadders: [6, 5],
            currentRepInLadder: 4
        )
    }
    .padding()
}
