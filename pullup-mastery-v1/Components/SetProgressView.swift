//
//  SetProgressView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI

struct SetProgressView: View {
    let totalSets: Int
    let currentSet: Int
    let completedSets: [WorkoutSet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set Progress")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(1...totalSets, id: \.self) { setNumber in
                    SetIndicator(
                        setNumber: setNumber,
                        isCurrent: setNumber == currentSet,
                        isCompleted: setNumber < currentSet,
                        reps: repCountForSet(setNumber)
                    )
                }
            }
            
            // Summary
            HStack {
                Text("Completed: \(completedSets.count)/\(totalSets)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !completedSets.isEmpty {
                    Text("Total Reps: \(completedSets.reduce(0) { $0 + $1.reps })")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func repCountForSet(_ setNumber: Int) -> Int? {
        return completedSets.first { $0.setNumber == setNumber }?.reps
    }
}

struct SetIndicator: View {
    let setNumber: Int
    let isCurrent: Bool
    let isCompleted: Bool
    let reps: Int?
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: isCurrent ? 2 : 1)
                    )
                
                if let reps = reps {
                    Text("\(reps)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                } else if isCurrent {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isCurrent ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isCurrent)
                } else {
                    Text("\(setNumber)")
                        .font(.caption)
                        .foregroundColor(textColor)
                }
            }
            
            Text("Set \(setNumber)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return .green.opacity(0.2)
        } else if isCurrent {
            return .blue.opacity(0.2)
        } else {
            return .gray.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .blue
        } else {
            return .gray.opacity(0.5)
        }
    }
    
    private var textColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .blue
        } else {
            return .secondary
        }
    }
}

// For Sub Max Volume - shows 2x5 grid layout (matching second image)
struct SubMaxSetProgressView: View {
    let currentSet: Int
    let totalSets: Int
    let completedSets: [WorkoutSet]
    
    var body: some View {
        VStack(spacing: 12) {
            // Set label
            HStack {
                Text("Set \(currentSet)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // 2x5 grid layout (matching second image)
            VStack(spacing: 8) {
                // First row (sets 1-5)
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { setNumber in
                        SubMaxSetIndicator(
                            setNumber: setNumber,
                            isCurrent: setNumber == currentSet,
                            isCompleted: setNumber < currentSet,
                            reps: repCountForSet(setNumber)
                        )
                    }
                }
                
                // Second row (sets 6-10)
                HStack(spacing: 8) {
                    ForEach(6...10, id: \.self) { setNumber in
                        SubMaxSetIndicator(
                            setNumber: setNumber,
                            isCurrent: setNumber == currentSet,
                            isCompleted: setNumber < currentSet,
                            reps: repCountForSet(setNumber)
                        )
                    }
                }
            }
        }
    }
    
    private func repCountForSet(_ setNumber: Int) -> Int? {
        return completedSets.first { $0.setNumber == setNumber }?.reps
    }
}

struct SubMaxSetIndicator: View {
    let setNumber: Int
    let isCurrent: Bool
    let isCompleted: Bool
    let reps: Int?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .frame(width: 50, height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 2)
                )
            
            Text(displayText)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(textColor)
        }
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return .green.opacity(0.2)
        } else if isCurrent {
            return .blue.opacity(0.2)
        } else {
            return .red.opacity(0.2)
        }
    }
    
    private var borderColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .blue
        } else {
            return .red
        }
    }
    
    private var textColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .blue
        } else {
            return .red
        }
    }
    
    private var displayText: String {
        if isCompleted, let reps = reps {
            return String(format: "%02d", reps)
        } else if isCurrent {
            return "↓"
        } else {
            return "-"
        }
    }
}

// For ladder workouts - shows progressive sets in a ladder (matching third image layout)
struct LadderSetProgressView: View {
    let currentLadder: Int
    let totalLadders: Int
    let completedLadders: [Int] // Array of max reps reached in each completed ladder
    let currentRepInLadder: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Set label
            HStack {
                Text("Ladder \(currentLadder)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // 5x1 grid of ladder indicators (improved sizing)
            HStack(spacing: 12) {
                ForEach(1...totalLadders, id: \.self) { ladderNumber in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(backgroundColorForLadder(ladderNumber))
                            .frame(width: 60, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(borderColorForLadder(ladderNumber), lineWidth: 2)
                            )
                        
                        Text(textForLadder(ladderNumber))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(textColorForLadder(ladderNumber))
                    }
                }
            }
        }
    }
    
    private func backgroundColorForLadder(_ ladderNumber: Int) -> Color {
        if ladderNumber < currentLadder {
            return .green.opacity(0.2)
        } else if ladderNumber == currentLadder {
            return .blue.opacity(0.2)
        } else {
            return .red.opacity(0.2)
        }
    }
    
    private func borderColorForLadder(_ ladderNumber: Int) -> Color {
        if ladderNumber < currentLadder {
            return .green
        } else if ladderNumber == currentLadder {
            return .blue
        } else {
            return .red
        }
    }
    
    private func textColorForLadder(_ ladderNumber: Int) -> Color {
        if ladderNumber < currentLadder {
            return .green
        } else if ladderNumber == currentLadder {
            return .blue
        } else {
            return .red
        }
    }
    
    private func textForLadder(_ ladderNumber: Int) -> String {
        if ladderNumber < currentLadder {
            // Completed ladder - show max reps achieved
            if let maxReps = completedLadders.indices.contains(ladderNumber - 1) ? completedLadders[ladderNumber - 1] : nil {
                return String(format: "%02d", maxReps)
            }
            return "00"
        } else if ladderNumber == currentLadder {
            // Current ladder - show arrow
            return "↓"
        } else {
            // Future ladder
            return "-"
        }
    }
}

struct LadderIndicator: View {
    let ladderNumber: Int
    let isCurrent: Bool
    let isCompleted: Bool
    let maxReps: Int?
    let currentRep: Int?
    
    var body: some View {
        HStack(spacing: 8) {
            // Ladder number
            Circle()
                .fill(backgroundColor)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(ladderNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                )
            
            // Progress bars for this ladder
            if let maxReps = maxReps {
                HStack(spacing: 2) {
                    ForEach(1...maxReps, id: \.self) { rep in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.green)
                            .frame(width: 12, height: 8)
                    }
                }
            } else if isCurrent, let currentRep = currentRep {
                HStack(spacing: 2) {
                    ForEach(1...currentRep, id: \.self) { rep in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.blue)
                            .frame(width: 12, height: 8)
                    }
                }
            }
            
            Spacer()
            
            if let maxReps = maxReps {
                Text("Max: \(maxReps)")
                    .font(.caption)
                    .foregroundColor(.green)
            } else if isCurrent {
                Text("In Progress")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isCurrent ? .blue.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 8))
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return .green.opacity(0.2)
        } else if isCurrent {
            return .blue.opacity(0.2)
        } else {
            return .gray.opacity(0.1)
        }
    }
    
    private var textColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .blue
        } else {
            return .secondary
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SetProgressView(
            totalSets: 3,
            currentSet: 2,
            completedSets: [
                WorkoutSet(setNumber: 1, reps: 8)
            ]
        )
        
        LadderSetProgressView(
            currentLadder: 3,
            totalLadders: 5,
            completedLadders: [6, 5],
            currentRepInLadder: 4
        )
    }
    .padding()
}
