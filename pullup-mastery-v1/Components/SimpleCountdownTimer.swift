//
//  SimpleCountdownTimer.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import Combine

struct SimpleCountdownTimer: View {
    @StateObject private var timerManager = CountdownTimerManager()
    let initialTime: Int
    let onTimerComplete: () -> Void
    let showFastForward: Bool
    
    init(initialTime: Int, showFastForward: Bool = false, onTimerComplete: @escaping () -> Void = {}) {
        self.initialTime = initialTime
        self.showFastForward = showFastForward
        self.onTimerComplete = onTimerComplete
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Timer display only - no controls (full-width design)
                ZStack {
                    Circle()
                        .stroke(.gray.opacity(0.3), lineWidth: 16)
                        .frame(maxWidth: .infinity, maxHeight: 320)
                        .aspectRatio(1, contentMode: .fit)
                    
                    Circle()
                        .trim(from: 0, to: timerManager.progress)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 28, lineCap: .round))
                                        .frame(maxWidth: .infinity, maxHeight: 320)
                        .aspectRatio(1, contentMode: .fit)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.05), value: timerManager.progress)
                    
                    VStack {
                        Text(timerManager.timeString)
                            .font(.system(size: 36, weight: .bold, design: .default))
                            .monospacedDigit()
                        
                        if timerManager.timeRemaining > 0 {
                            Text("Rest")
                                .font(.title)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Done!")
                                .font(.title)
                                .foregroundColor(.green)
                                .fontWeight(.bold)
                        }
                    }
                }
            
            
            // Temporary fast forward button (for testing only)
            if showFastForward && timerManager.hasStarted && timerManager.timeRemaining > 5 {
                Button(action: {
                    timerManager.fastForwardTo5Seconds()
                    HapticManager.shared.light()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.fill")
                        Text("⏩ Skip Rest")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .onAppear {
            timerManager.startTimer(duration: initialTime)
        }
        .onReceive(timerManager.$timeRemaining) { time in
            if time == 0 && timerManager.hasStarted {
                onTimerComplete()
                HapticManager.shared.success()
            }
        }
    }
}

class CountdownTimerManager: ObservableObject {
    @Published var timeRemaining: Int = 0
    @Published var progress: Double = 0.0
    @Published var hasStarted: Bool = false
    
    private var timer: AnyCancellable?
    private var totalTime: Int = 0
    private var exactTimeRemaining: Double = 0.0
    
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func startTimer(duration: Int) {
        totalTime = duration
        timeRemaining = duration
        exactTimeRemaining = Double(duration)
        hasStarted = true
        updateProgress()
        
        timer = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if self.exactTimeRemaining > 0 {
                    self.exactTimeRemaining -= 0.01
                    let newTimeRemaining = Int(ceil(self.exactTimeRemaining))
                    
                    if newTimeRemaining != self.timeRemaining {
                        self.timeRemaining = newTimeRemaining
                    }
                    
                    self.updateProgress()
                } else {
                    self.exactTimeRemaining = 0
                    self.timeRemaining = 0
                    self.stopTimer()
                }
            }
    }
    
    func stopTimer() {
        hasStarted = false
        timer?.cancel()
    }
    
    func fastForwardTo5Seconds() {
        exactTimeRemaining = 5.0
        timeRemaining = 5
        updateProgress()
    }
    
    private func updateProgress() {
        if totalTime > 0 {
            progress = exactTimeRemaining / Double(totalTime)
        } else {
            progress = 0.0
        }
    }
}

#Preview {
    SimpleCountdownTimer(initialTime: 60, showFastForward: true) {
        print("Timer completed!")
    }
    .padding()
}
