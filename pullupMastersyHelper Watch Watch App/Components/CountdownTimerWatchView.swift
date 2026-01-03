//
//  CountdownTimerWatchView.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import SwiftUI
import Combine
import WatchKit

struct CountdownTimerWatchView: View {
    @StateObject private var timerManager = CountdownTimerManagerWatch()
    let initialTime: Int
    let onTimerComplete: () -> Void
    
    @State private var timerID: UUID = UUID()
    
    private let borderStrokeWidth: CGFloat = 8
    
    init(initialTime: Int, onTimerComplete: @escaping () -> Void = {}) {
        self.initialTime = initialTime
        self.onTimerComplete = onTimerComplete
    }
    
    var body: some View {
        let screenBounds = WKInterfaceDevice.current().screenBounds
        let screenWidth = screenBounds.width
        let screenHeight = screenBounds.height
        
        return VStack(spacing: 0) {
            Text(timerManager.timeString)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .padding(.top, 8)
            
            if timerManager.timeRemaining > 0 {
                Text("Rest")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Done!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .frame(width: screenWidth, height: screenHeight)
        .overlay(
            // Edge border - counter-clockwise progression
            RoundedRectangle(cornerRadius: screenWidth * 0.25)
                .inset(by: borderStrokeWidth * 0.5) // Inset by half width so stroke stays on screen
                .trim(from: 0, to: timerManager.progress)
                .stroke(
                    Color.blue,
                    style: StrokeStyle(lineWidth: borderStrokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(270))
                .frame(width: screenHeight, height: screenWidth)
                .animation(.linear(duration: 0.1), value: timerManager.progress)
        )
        .ignoresSafeArea()
        .overlay(
            // Fast forward button for testing (DEBUG only)
            Group {
                #if DEBUG
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            timerManager.fastForwardTo5Seconds()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 8)
                        .padding(.bottom, 8)
                    }
                }
                #else
                EmptyView()
                #endif
            }
        )
        .onAppear {
            timerManager.startTimer(duration: initialTime, timerID: timerID)
        }
        .onReceive(timerManager.$timeRemaining) { time in
            if time == 0 && timerManager.hasStarted {
                onTimerComplete()
                HapticManagerWatch.shared.success()
            }
        }
        .onDisappear {
            timerManager.cleanup(timerID: timerID)
        }
    }
}

class CountdownTimerManagerWatch: ObservableObject {
    @Published var timeRemaining: Int = 0
    @Published var progress: Double = 0.0
    @Published var hasStarted: Bool = false
    
    private var timer: AnyCancellable?
    private var totalTime: Int = 0
    private var exactTimeRemaining: Double = 0.0
    private var timerEndTime: Date?
    private var currentTimerID: UUID?
    
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func startTimer(duration: Int, timerID: UUID) {
        totalTime = duration
        exactTimeRemaining = Double(duration)
        timeRemaining = duration
        hasStarted = true
        currentTimerID = timerID
        timerEndTime = Date().addingTimeInterval(exactTimeRemaining)
        
        saveTimerState(timerID: timerID)
        updateProgress()
        
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.updateTimer()
            }
    }
    
    private func updateTimer() {
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
                exactTimeRemaining = 0
                timeRemaining = 0
                stopTimer()
            }
        } else {
            if exactTimeRemaining > 0 {
                exactTimeRemaining -= 0.1
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
        
        if let timerID = currentTimerID {
            clearTimerState(timerID: timerID)
        }
        
        timerEndTime = nil
        currentTimerID = nil
    }
    
    func cleanup(timerID: UUID) {
        if currentTimerID == timerID {
            stopTimer()
        }
    }
    
    func fastForwardTo5Seconds() {
        guard hasStarted, let endTime = timerEndTime else { return }
        
        // Set timer to 5 seconds remaining
        let now = Date()
        timerEndTime = now.addingTimeInterval(5.0)
        exactTimeRemaining = 5.0
        timeRemaining = 5
        updateProgress()
        saveTimerState(timerID: currentTimerID)
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
        
        if let savedTotalTime = UserDefaults.standard.object(forKey: "\(key)_total") as? Int {
            totalTime = savedTotalTime
        }
        
        let savedEndTime = Date(timeIntervalSince1970: endTimeInterval)
        let now = Date()
        let remaining = savedEndTime.timeIntervalSince(now)
        
        if remaining > 0 {
            timerEndTime = savedEndTime
            exactTimeRemaining = remaining
            timeRemaining = Int(ceil(exactTimeRemaining))
            updateProgress()
        } else {
            exactTimeRemaining = 0
            timeRemaining = 0
            updateProgress()
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
    CountdownTimerWatchView(initialTime: 60) {
        print("Timer completed!")
    }
    .padding()
}

