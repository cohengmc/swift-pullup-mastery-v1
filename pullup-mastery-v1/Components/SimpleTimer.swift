//
//  SimpleTimer.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import Combine

struct SimpleTimer: View {
    @StateObject private var timerManager = TimerManager()
    let initialTime: Int
    let onTimerComplete: () -> Void
    
    @State private var hasStarted = false
    
    init(initialTime: Int, onTimerComplete: @escaping () -> Void = {}) {
        self.initialTime = initialTime
        self.onTimerComplete = onTimerComplete
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Timer display
            ZStack {
                Circle()
                    .stroke(.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timerManager.progress)
                
                VStack {
                    Text(timerManager.timeString)
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    
                    if timerManager.timeRemaining > 0 {
                        Text("Rest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if hasStarted {
                        Text("Done!")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    }
                }
            }
            
            // Controls
            HStack(spacing: 20) {
                Button(action: {
                    if timerManager.isRunning {
                        timerManager.pauseTimer()
                        HapticManager.shared.light()
                    } else {
                        if !hasStarted {
                            hasStarted = true
                            timerManager.startTimer(duration: initialTime)
                            HapticManager.shared.medium()
                        } else {
                            timerManager.resumeTimer()
                            HapticManager.shared.medium()
                        }
                    }
                }) {
                    Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(.blue)
                        .clipShape(Circle())
                }
                .disabled(timerManager.timeRemaining == 0 && hasStarted)
                
                Button(action: {
                    timerManager.resetTimer()
                    hasStarted = false
                    HapticManager.shared.light()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(.gray)
                        .clipShape(Circle())
                }
            }
            
            // Quick time adjustments
            if !timerManager.isRunning && !hasStarted {
                HStack(spacing: 15) {
                    TimeAdjustButton(seconds: -30) {
                        timerManager.adjustTime(by: -30, initialTime: initialTime)
                    }
                    
                    TimeAdjustButton(seconds: -10) {
                        timerManager.adjustTime(by: -10, initialTime: initialTime)
                    }
                    
                    TimeAdjustButton(seconds: 10) {
                        timerManager.adjustTime(by: 10, initialTime: initialTime)
                    }
                    
                    TimeAdjustButton(seconds: 30) {
                        timerManager.adjustTime(by: 30, initialTime: initialTime)
                    }
                }
            }
        }
        .onAppear {
            timerManager.setInitialTime(initialTime)
        }
        .onReceive(timerManager.$timeRemaining) { time in
            if time == 0 && hasStarted {
                onTimerComplete()
                HapticManager.shared.success()
            }
        }
    }
}

struct TimeAdjustButton: View {
    let seconds: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            HapticManager.shared.selection()
        }) {
            Text("\(seconds > 0 ? "+" : "")\(seconds)s")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

class TimerManager: ObservableObject {
    @Published var timeRemaining: Int = 0
    @Published var isRunning: Bool = false
    @Published var progress: Double = 0.0
    
    private var timer: AnyCancellable?
    private var totalTime: Int = 0
    
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func setInitialTime(_ time: Int) {
        timeRemaining = time
        totalTime = time
        updateProgress()
    }
    
    func startTimer(duration: Int) {
        totalTime = duration
        timeRemaining = duration
        isRunning = true
        updateProgress()
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    self.updateProgress()
                } else {
                    self.stopTimer()
                }
            }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.cancel()
    }
    
    func resumeTimer() {
        isRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    self.updateProgress()
                } else {
                    self.stopTimer()
                }
            }
    }
    
    func stopTimer() {
        isRunning = false
        timer?.cancel()
    }
    
    func resetTimer() {
        stopTimer()
        timeRemaining = totalTime
        updateProgress()
    }
    
    func adjustTime(by seconds: Int, initialTime: Int) {
        let newTime = max(0, timeRemaining + seconds)
        timeRemaining = newTime
        totalTime = max(initialTime, newTime)
        updateProgress()
    }
    
    private func updateProgress() {
        if totalTime > 0 {
            progress = 1.0 - (Double(timeRemaining) / Double(totalTime))
        } else {
            progress = 0.0
        }
    }
}

#Preview {
    SimpleTimer(initialTime: 60) {
        print("Timer completed!")
    }
    .padding()
}
