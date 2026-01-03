//
//  SetProgressWatchView.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import SwiftUI

struct SetProgressWatchView: View {
    let totalSets: Int
    let completedSets: [Int] // Array of rep counts for completed sets
//    let currentReps: Int? // Reps for current set, nil if not started
    
    private var currentSet: Int {
        completedSets.count + 1
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Set \(currentSet)/\(totalSets)")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Simple progress indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    // Progress based on completedSets
                    if completedSets.isEmpty {
                        // When no sets completed, show just a circle at the beginning
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .offset(x: 0)
                    } else {
                        // When sets are completed, fill bar proportionally
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * CGFloat(completedSets.count) / CGFloat(totalSets), height: 8)
                    }
                }
            }
            .frame(height: 8)
            
            // Show current reps if available
//            if let reps = currentReps, reps > 0 {
//                Text("\(reps) reps")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 20) {
        // No sets completed - shows circle
        SetProgressWatchView(
            totalSets: 3,
            completedSets: []
        )
        
        // One set completed
        SetProgressWatchView(
            totalSets: 3,
            completedSets: [8]
        )
        
        // Two sets completed
        SetProgressWatchView(
            totalSets: 3,
            completedSets: [8, 7]
        )
        
        // All sets completed
        SetProgressWatchView(
            totalSets: 3,
            completedSets: [8, 7, 6]
        )
    }
    .padding()
}

