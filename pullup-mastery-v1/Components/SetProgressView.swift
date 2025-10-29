//
//  SetProgressView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI

struct SetProgressView: View {
    let totalSets: Int
    let completedSets: [Int] // Array of rep counts for completed sets
    let currentReps: Int? // Reps for current set, nil if not started
    
    private var currentSet: Int {
        completedSets.count + 1
    }
    
    // Threshold for when to use scrolling vs static layout
    private let scrollThreshold = 5
    
    var body: some View {
        if totalSets <= scrollThreshold {
            // Static layout for 5 or fewer sets
            staticProgressView
        } else {
            // Scrolling layout for more than 5 sets
            scrollingProgressView
        }
    }
    
    // MARK: - Static Progress View (Original)
    private var staticProgressView: some View {
        VStack(spacing: 16) {
            // Progress indicators
            HStack(spacing: 20) {
                ForEach(1...totalSets, id: \.self) { setNumber in
                    SetBoxView(
                        setNumber: setNumber,
                        totalSets: totalSets,
                        completedSets: completedSets,
                        currentReps: currentReps,
                        currentSet: currentSet
                    )
                }
            }
        }
    }
    
    // MARK: - Scrolling Progress View (For 10+ sets)
    private var scrollingProgressView: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        // Invisible anchor at start
                        Color.clear
                            .frame(width: 1)
                            .id("start")
                        
                        ForEach(1...totalSets, id: \.self) { setNumber in
                            SetBoxView(
                                setNumber: setNumber,
                                totalSets: totalSets,
                                completedSets: completedSets,
                                currentReps: currentReps,
                                currentSet: currentSet
                            )
                            .id(setNumber)
                        }
                        
                        // Invisible anchor at end
                        Color.clear
                            .frame(width: 1)
                            .id("end")
                    }
                    .padding(.horizontal, 20)
                }
                .scrollDisabled(true)
                .onChange(of: currentSet) { oldValue, newValue in
                    scrollToPercentage(proxy: proxy, geometry: geometry)
                }
                .onAppear {
                    scrollToPercentage(proxy: proxy, geometry: geometry)
                }
            }
        }
    }
    
    // MARK: - Scrolling Logic
    private var scrollPercentage: Double {
        let linearProgress = Double(currentSet - 1) / Double(totalSets - 1)
        return customWorkoutEasing(linearProgress)
    }
    
    // Custom easing: slow start, fast middle, slow end
    private func customWorkoutEasing(_ x: Double) -> Double {
        // Very slow start (sets 1-3) - only scroll 15%
        if x < 0.3 {
            return x * 0.5
        }
        // Fast middle (sets 4-7) - scroll 55% during this phase
        else if x < 0.7 {
            return 0.15 + (x - 0.3) * 1.375
        }
        // Slow finish (sets 8-10) - final 30% scroll
        else {
            return 0.70 + (x - 0.7) * 1.0
        }
    }
    
    private func scrollToPercentage(proxy: ScrollViewProxy, geometry: GeometryProxy) {
        let setWidth: CGFloat = 60
        let setSpacing: CGFloat = 20
        
        // Calculate total content width
        let totalBoxesWidth = CGFloat(totalSets) * setWidth
        let totalSpacingWidth = CGFloat(totalSets - 1) * setSpacing
        let totalContentWidth = totalBoxesWidth + totalSpacingWidth + 40 // 40 for padding
        
        // Calculate scrollable distance
        let scrollableDistance = max(0, totalContentWidth - geometry.size.width)
        
        // Calculate target offset based on percentage
        let targetOffset = scrollableDistance * scrollPercentage
        
        // Find which set ID to scroll to that approximates this offset
        let offsetPerSet = (setWidth + setSpacing)
        let targetSetFloat = targetOffset / offsetPerSet + 1
        let targetSet = min(max(1, Int(round(targetSetFloat))), totalSets)
        
        withAnimation(.easeInOut(duration: 0.5)) {
            if scrollPercentage == 0 {
                proxy.scrollTo("start", anchor: .leading)
            } else if scrollPercentage >= 0.99 {
                proxy.scrollTo("end", anchor: .trailing)
            } else {
                proxy.scrollTo(targetSet, anchor: .leading)
            }
        }
    }
}

// MARK: - Set Box Component (Extracted for reuse)
struct SetBoxView: View {
    let setNumber: Int
    let totalSets: Int
    let completedSets: [Int]
    let currentReps: Int?
    let currentSet: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Set \(setNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColorForSet)
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColorForSet, lineWidth: 2)
                    )
                
                Text(textForSet)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(textColorForSet)
            }
        }
    }
    
    private var backgroundColorForSet: Color {
        if setNumber < currentSet {
            return .green.opacity(0.2)
        } else if setNumber == currentSet {
            return .blue.opacity(0.2)
        } else {
            return .red.opacity(0.2)
        }
    }
    
    private var borderColorForSet: Color {
        if setNumber < currentSet {
            return .green
        } else if setNumber == currentSet {
            return .blue
        } else {
            return .red
        }
    }
    
    private var textColorForSet: Color {
        if setNumber < currentSet {
            return .green
        } else if setNumber == currentSet {
            return .blue
        } else {
            return .red
        }
    }
    
    private var textForSet: String {
        if setNumber < currentSet {
            // Completed set - show the rep count
            let reps = completedSets[setNumber - 1]
            return String(format: "%02d", reps)
        } else if setNumber == currentSet {
            // Current set - show current reps or arrow if not started
            if let reps = currentReps, reps > 0 {
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

#Preview {
    VStack(spacing: 20) {
        // Example 1: On set 2, with 8 reps completed in set 1, currently at 6 reps
        SetProgressView(
            totalSets: 3,
            completedSets: [8],
            currentReps: 6
        )
        
        // Example 2: On set 3, with sets 1 and 2 completed, current set just started
        SetProgressView(
            totalSets: 5,
            completedSets: [10, 8],
            currentReps: nil
        )
        
        // Example 3: First set, no reps yet
        SetProgressView(
            totalSets: 3,
            completedSets: [],
            currentReps: nil
        )
        
        // Example 4: SubMax workout with 10 sets - should scroll
        SetProgressView(
            totalSets: 10,
            completedSets: [8, 7, 6],
            currentReps: 5
        )
    }
    .padding()
}
