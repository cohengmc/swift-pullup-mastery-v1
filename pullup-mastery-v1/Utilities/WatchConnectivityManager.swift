//
//  WatchConnectivityManager.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import Foundation
import WatchConnectivity
import SwiftData

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    @Published var workoutCompleted = false
    
    // MARK: - Message Queue System
    private var isActivated = false
    private var pendingMessages: [[String: Any]] = []
    private let session = WCSession.default
    
    override init() {
        super.init()
        print("📱 [Phone] WatchConnectivityManager initializing...")
        if WCSession.isSupported() {
            print("📱 [Phone] WCSession is supported")
            session.delegate = self
            logSessionState(session, prefix: "📱 [Phone] Before activation")
            session.activate()
        } else {
            print("❌ [Phone] WCSession is NOT supported on this device")
        }
    }
    
    // MARK: - Helper Methods
    
    private func logSessionState(_ session: WCSession, prefix: String = "") {
        let stateString: String
        switch session.activationState {
        case .notActivated:
            stateString = "notActivated"
        case .inactive:
            stateString = "inactive"
        case .activated:
            stateString = "activated"
        @unknown default:
            stateString = "unknown"
        }
        
        print("\(prefix) Session State: \(stateString)")
        print("\(prefix) isReachable: \(session.isReachable)")
        print("\(prefix) isPaired: \(session.isPaired)")
        print("\(prefix) isWatchAppInstalled: \(session.isWatchAppInstalled)")
        
        if session.isReachable {
            print("\(prefix) ✅ Watch is reachable")
        } else {
            print("\(prefix) ⚠️ Watch is NOT reachable")
        }
        
        if !session.isPaired {
            print("\(prefix) ⚠️ Watch is NOT paired")
        }
        
        if !session.isWatchAppInstalled {
            print("\(prefix) ⚠️ Watch app is NOT installed")
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ [Phone] WCSession activation failed: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ [Phone] Error domain: \(nsError.domain), code: \(nsError.code)")
                print("❌ [Phone] Error userInfo: \(nsError.userInfo)")
            }
        } else {
            let stateString: String
            switch activationState {
            case .notActivated:
                stateString = "notActivated"
            case .inactive:
                stateString = "inactive"
            case .activated:
                stateString = "activated"
            @unknown default:
                stateString = "unknown"
            }
            print("✅ [Phone] WCSession activated with state: \(stateString) (\(activationState.rawValue))")
            logSessionState(session, prefix: "📱 [Phone] After activation")
            
            // Process pending messages when session is activated
            if activationState == .activated {
                isActivated = true
                print("📤 [Phone] Session activated, sending \(pendingMessages.count) pending messages...")
                for message in pendingMessages {
                    send(message: message)
                }
                pendingMessages.removeAll()
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("⚠️ [Phone] WCSession became inactive")
        logSessionState(session, prefix: "📱 [Phone]")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("⚠️ [Phone] WCSession deactivated, reactivating...")
        session.activate()
    }
    
    // MARK: - Receiving Messages from Watch
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📨 [Phone] Received message from watch: \(message)")
        DispatchQueue.main.async { [weak self] in
            self?.handleReceivedData(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📨 [Phone] Received message from watch (with reply): \(message)")
        DispatchQueue.main.async { [weak self] in
            self?.handleReceivedData(message)
        }
        let reply = ["received": true]
        print("📤 [Phone] Sending reply to watch: \(reply)")
        replyHandler(reply)
    }
    
    // MARK: - Receiving Application Context from Watch
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("📦 [Phone] Received application context from watch: \(applicationContext)")
        DispatchQueue.main.async { [weak self] in
            self?.handleReceivedData(applicationContext)
        }
    }
    
    // MARK: - Receiving UserInfo from Watch (Background Transfer)
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("📨 [Phone] Received userInfo from watch: \(userInfo)")
        DispatchQueue.main.async { [weak self] in
            self?.handleReceivedData(userInfo)
        }
    }
    
    // MARK: - Handle Received Data
    
    private func handleReceivedData(_ data: [String: Any]) {
        // Check if this is workout data
        if let messageType = data["messageType"] as? String,
           messageType == WorkoutDataTransfer.MessageType.workoutData.rawValue,
           let workoutData = data[WorkoutDataTransfer.workoutDataKey] as? [String: Any],
           let workout = WorkoutDataTransfer.decodeWorkout(workoutData) {
            print("✅ [Phone] Received workout data from watch")
            saveWorkoutToDatabase(workout)
            workoutCompleted = true
            NotificationCenter.default.post(name: NSNotification.Name("WatchWorkoutCompleted"), object: nil)
        } else if let workoutData = data[WorkoutDataTransfer.workoutDataKey] as? [String: Any],
                  let workout = WorkoutDataTransfer.decodeWorkout(workoutData) {
            // Fallback: check for workoutData key directly
            print("✅ [Phone] Received workout data (without messageType)")
            saveWorkoutToDatabase(workout)
            workoutCompleted = true
            NotificationCenter.default.post(name: NSNotification.Name("WatchWorkoutCompleted"), object: nil)
        } else if data["workoutCompleted"] as? Bool == true {
            // Legacy support for boolean flag (shouldn't happen with new code)
            print("⚠️ [Phone] Received legacy workoutCompleted flag (no data)")
            workoutCompleted = true
            NotificationCenter.default.post(name: NSNotification.Name("WatchWorkoutCompleted"), object: nil)
        }
    }
    
    // MARK: - Save Workout to Database
    
    private func saveWorkoutToDatabase(_ workout: Workout) {
        // Get the model context from the app
        // Note: This requires access to ModelContext, which we'll need to inject
        // For now, post a notification with the workout data
        NotificationCenter.default.post(
            name: NSNotification.Name("WorkoutDataReceived"),
            object: nil,
            userInfo: ["workout": workout]
        )
        print("📢 [Phone] Posted WorkoutDataReceived notification with workout: \(workout.id)")
    }
    
    // MARK: - Sending Messages to Watch
    
    /// Sends a workout to the watch
    func sendWorkoutData(_ workout: Workout) {
        let workoutData = WorkoutDataTransfer.encodeWorkout(workout)
        let message: [String: Any] = [
            "messageType": WorkoutDataTransfer.MessageType.workoutData.rawValue,
            WorkoutDataTransfer.workoutDataKey: workoutData
        ]
        
        if isActivated {
            send(message: message)
        } else {
            print("⏳ [Phone] Session not ready. Queuing workout data.")
            pendingMessages.append(message)
        }
    }
    
    /// Internal method to send message (with fallback to Application Context and UserInfo)
    private func send(message: [String: Any]) {
        logSessionState(session, prefix: "📱 [Phone] Before sending message")
        
        if session.isReachable {
            print("📤 [Phone] Sending message to watch (real-time): \(message)")
            session.sendMessage(message, replyHandler: { reply in
                print("✅ [Phone] Received reply from watch: \(reply)")
            }, errorHandler: { error in
                print("❌ [Phone] Error sending message: \(error.localizedDescription)")
                // Fallback to Application Context
                self.sendViaApplicationContext(message)
            })
        } else {
            print("⚠️ [Phone] Watch not reachable, using Application Context...")
            sendViaApplicationContext(message)
        }
    }
    
    /// Sends message via Application Context (latest state)
    private func sendViaApplicationContext(_ message: [String: Any]) {
        do {
            try session.updateApplicationContext(message)
            print("📦 [Phone] Sent via Application Context")
        } catch {
            print("❌ [Phone] Error sending via Application Context: \(error.localizedDescription)")
            // Fallback to UserInfo transfer (guaranteed delivery)
            sendViaUserInfo(message)
        }
    }
    
    /// Sends message via UserInfo transfer (guaranteed background delivery)
    private func sendViaUserInfo(_ message: [String: Any]) {
        session.transferUserInfo(message)
        print("📨 [Phone] Sent via UserInfo transfer (guaranteed delivery)")
    }
    
    /// Legacy method for sending generic messages
    func sendMessageToWatch(_ message: [String: Any]) {
        if isActivated {
            send(message: message)
        } else {
            print("⏳ [Phone] Session not ready. Queuing message.")
            pendingMessages.append(message)
        }
    }
}

