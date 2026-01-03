//
//  TimerWithSetsView.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import SwiftUI
import WatchKit

struct TimerWithSetsView: View {
    let initialTime: Int
    let onTimerComplete: () -> Void
    let totalSets: Int
    let completedSets: [Int]
    let isTimerActive: Bool
    
    init(
        initialTime: Int,
        totalSets: Int,
        completedSets: [Int],
        isTimerActive: Bool = true,
        onTimerComplete: @escaping () -> Void = {}
    ) {
        self.initialTime = initialTime
        self.totalSets = totalSets
        self.completedSets = completedSets
        self.isTimerActive = isTimerActive
        self.onTimerComplete = onTimerComplete
    }
    
    var body: some View {
        let screenBounds = WKInterfaceDevice.current().screenBounds
        let screenWidth = screenBounds.width
        let screenHeight = screenBounds.height
        
        return ZStack {
            // SetProgress at the bottom
            VStack {
                Spacer()
                SetProgressWatchView(
                    totalSets: totalSets,
                    completedSets: completedSets
                )
                .frame(maxWidth: screenWidth * 0.7) // Make it narrower (75% of screen width)
                .padding(.bottom, 10)
            }
            
            // Timer overlay on top - only show and run when isTimerActive is true
            if isTimerActive {
                CountdownTimerWatchView(initialTime: initialTime, onTimerComplete: onTimerComplete)
                    .zIndex(1000) // Ensure timer is on top
            }
        }
        .frame(width: screenWidth, height: screenHeight)
        .ignoresSafeArea()
    }
}

#Preview {
    VStack(spacing: 20) {
        TimerWithSetsView(
            initialTime: 60,
            totalSets: 3,
            completedSets: [8,5],
            isTimerActive: true
        ) {
            print("Timer completed!")
        }
        
        TimerWithSetsView(
            initialTime: 60,
            totalSets: 3,
            completedSets: [8,5],
            isTimerActive: false
        ) {
            print("Timer completed!")
        }
    }
}

