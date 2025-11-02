//
//  SimpleCountdownTimer.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import Combine
import UIKit

struct SimpleCountdownTimer: View {
    @StateObject private var timerManager = CountdownTimerManager()
    let initialTime: Int
    let onTimerComplete: () -> Void
    let showFastForward: Bool
    
    // Unique ID for this timer instance to persist across backgrounding
    @State private var timerID: UUID = UUID()
    
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
            
            
            // Temporary fast forward button (for testing only - DEBUG only, controlled by feature flag)
            #if DEBUG
            if FeatureFlags.hideFeature && showFastForward && timerManager.hasStarted && timerManager.timeRemaining > 5 {
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
            #endif
        }
        .onAppear {
            timerManager.startTimer(duration: initialTime, timerID: timerID)
        }
        .onReceive(timerManager.$timeRemaining) { time in
            if time == 0 && timerManager.hasStarted {
                onTimerComplete()
                HapticManager.shared.success()
            }
        }
        .onDisappear {
            timerManager.cleanup(timerID: timerID)
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
    private var timerEndTime: Date?
    private var currentTimerID: UUID?
    
    // NotificationCenter observers for app lifecycle
    private var backgroundObserver: AnyCancellable?
    private var foregroundObserver: AnyCancellable?
    
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    init() {
        setupAppLifecycleObservers()
    }
    
    func startTimer(duration: Int, timerID: UUID) {
        totalTime = duration
        exactTimeRemaining = Double(duration)
        timeRemaining = duration
        hasStarted = true
        currentTimerID = timerID
        timerEndTime = Date().addingTimeInterval(exactTimeRemaining)
        
        // Save to UserDefaults for persistence
        saveTimerState(timerID: timerID)
        
        updateProgress()
        
        timer = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.updateTimer()
            }
    }
    
    private func updateTimer() {
        // If we have a target end time, calculate remaining based on actual time
        if let endTime = timerEndTime {
            let now = Date()
            let remaining = endTime.timeIntervalSince(now)
            
            if remaining > 0 {
                exactTimeRemaining = remaining
                let newTimeRemaining = Int(ceil(exactTimeRemaining))
                
                if newTimeRemaining != timeRemaining {
                    timeRemaining = newTimeRemaining
                }
                
                updateProgress()
                saveTimerState(timerID: currentTimerID)
            } else {
                // Timer expired
                exactTimeRemaining = 0
                timeRemaining = 0
                stopTimer()
            }
        } else {
            // Fallback to old behavior if no end time set
            if exactTimeRemaining > 0 {
                exactTimeRemaining -= 0.01
                let newTimeRemaining = Int(ceil(exactTimeRemaining))
                
                if newTimeRemaining != timeRemaining {
                    timeRemaining = newTimeRemaining
                }
                
                updateProgress()
            } else {
                exactTimeRemaining = 0
                timeRemaining = 0
                stopTimer()
            }
        }
    }
    
    func stopTimer() {
        hasStarted = false
        timer?.cancel()
        timer = nil
        
        // Clear persisted state
        if let timerID = currentTimerID {
            clearTimerState(timerID: timerID)
        }
        
        timerEndTime = nil
        currentTimerID = nil
    }
    
    func fastForwardTo5Seconds() {
        timerEndTime = Date().addingTimeInterval(5.0)
        exactTimeRemaining = 5.0
        timeRemaining = 5
        updateProgress()
        
        if let timerID = currentTimerID {
            saveTimerState(timerID: timerID)
        }
    }
    
    func cleanup(timerID: UUID) {
        // Only cleanup if this is the current timer
        if currentTimerID == timerID {
            stopTimer()
        }
    }
    
    private func setupAppLifecycleObservers() {
        // Observe when app goes to background
        backgroundObserver = NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.saveTimerState(timerID: self?.currentTimerID)
            }
        
        // Observe when app comes to foreground
        foregroundObserver = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.restoreTimerFromBackground()
            }
    }
    
    private func saveTimerState(timerID: UUID?) {
        guard let timerID = timerID, let endTime = timerEndTime else { return }
        
        let key = "timer_\(timerID.uuidString)"
        UserDefaults.standard.set(endTime.timeIntervalSince1970, forKey: key)
        UserDefaults.standard.set(totalTime, forKey: "\(key)_total")
    }
    
    private func restoreTimerFromBackground() {
        guard let timerID = currentTimerID, hasStarted else { return }
        
        let key = "timer_\(timerID.uuidString)"
        guard let endTimeInterval = UserDefaults.standard.object(forKey: key) as? TimeInterval else { return }
        
        // Restore totalTime if available
        if let savedTotalTime = UserDefaults.standard.object(forKey: "\(key)_total") as? Int {
            totalTime = savedTotalTime
        }
        
        let savedEndTime = Date(timeIntervalSince1970: endTimeInterval)
        let now = Date()
        let remaining = savedEndTime.timeIntervalSince(now)
        
        if remaining > 0 {
            // Timer still has time remaining - restore it
            timerEndTime = savedEndTime
            exactTimeRemaining = remaining
            timeRemaining = Int(ceil(exactTimeRemaining))
            updateProgress()
        } else {
            // Timer expired while in background - set to 0 first (before stopping) to trigger completion
            exactTimeRemaining = 0
            timeRemaining = 0
            updateProgress()
            // Give a moment for the @Published update to propagate and trigger onReceive
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.stopTimer()
            }
        }
    }
    
    private func clearTimerState(timerID: UUID) {
        let key = "timer_\(timerID.uuidString)"
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: "\(key)_total")
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
