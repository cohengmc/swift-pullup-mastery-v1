//
//  WatchConnectivityManagerWatch.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import Foundation
import WatchConnectivity
import SwiftData

class WatchConnectivityManagerWatch: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManagerWatch()
    
    // MARK: - Message Queue System
    private var isActivated = false
    private var pendingMessages: [[String: Any]] = []
    private let session = WCSession.default
    
    override init() {
        super.init()
        print("⌚ [Watch] WatchConnectivityManagerWatch initializing...")
        if WCSession.isSupported() {
            print("⌚ [Watch] WCSession is supported")
            session.delegate = self
            logSessionState(session, prefix: "⌚ [Watch] Before activation")
            session.activate()
        } else {
            print("❌ [Watch] WCSession is NOT supported on this device")
        }
    }
    
    // MARK: - Helper Methods
    
    nonisolated private func logSessionState(_ session: WCSession, prefix: String = "") {
        // Access session properties safely - WCSession properties should be accessed from main thread
        Task { @MainActor in
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
            print("\(prefix) isCompanionAppInstalled: \(session.isCompanionAppInstalled)")
            
            if session.isReachable {
                print("\(prefix) ✅ Phone is reachable")
            } else {
                print("\(prefix) ⚠️ Phone is NOT reachable")
            }
            
            if !session.isCompanionAppInstalled {
                print("\(prefix) ⚠️ Companion app (phone) is NOT installed")
            }
        }
    }
    
    // MARK: - WCSessionDelegate
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ [Watch] WCSession activation failed: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ [Watch] Error domain: \(nsError.domain), code: \(nsError.code)")
                print("❌ [Watch] Error userInfo: \(nsError.userInfo)")
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
            print("✅ [Watch] WCSession activated with state: \(stateString) (\(activationState.rawValue))")
            self.logSessionState(session, prefix: "⌚ [Watch] After activation")
            
            // Process pending messages when session is activated
            if activationState == .activated {
                Task { @MainActor in
                    self.isActivated = true
                    print("📤 [Watch] Session activated, sending \(self.pendingMessages.count) pending messages...")
                    for message in self.pendingMessages {
                        self.send(message: message)
                    }
                    self.pendingMessages.removeAll()
                }
            }
        }
    }
    
    // MARK: - Sending Messages to Phone
    
    /// Sends workout data to the phone
    func sendWorkoutData(_ workout: Workout) {
        let workoutData = WorkoutDataTransferWatch.encodeWorkout(workout)
        let message: [String: Any] = [
            "messageType": WorkoutDataTransferWatch.MessageType.workoutData.rawValue,
            WorkoutDataTransferWatch.workoutDataKey: workoutData
        ]
        
        if isActivated {
            send(message: message)
        } else {
            print("⏳ [Watch] Session not ready. Queuing workout data.")
            pendingMessages.append(message)
        }
    }
    
    /// Legacy method - sends workout completion notification (now sends actual data)
    func notifyWorkoutCompleted(workout: Workout) {
        print("📤 [Watch] notifyWorkoutCompleted() called")
        sendWorkoutData(workout)
    }
    
    /// Internal method to send message (with fallback to Application Context and UserInfo)
    private func send(message: [String: Any]) {
        logSessionState(session, prefix: "⌚ [Watch] Before sending message")
        
        if session.isReachable {
            print("📤 [Watch] Sending message to phone (real-time): \(message)")
            session.sendMessage(message, replyHandler: { reply in
                print("✅ [Watch] Received reply from phone: \(reply)")
            }, errorHandler: { error in
                print("❌ [Watch] Error sending message: \(error.localizedDescription)")
                // Fallback to Application Context
                self.sendViaApplicationContext(message)
            })
        } else {
            print("⚠️ [Watch] Phone not reachable, using Application Context...")
            sendViaApplicationContext(message)
        }
    }
    
    /// Sends message via Application Context (latest state)
    private func sendViaApplicationContext(_ message: [String: Any]) {
        guard session.activationState == .activated else {
            print("❌ [Watch] Cannot send via Application Context: session not activated")
            // Fallback to UserInfo transfer
            sendViaUserInfo(message)
            return
        }
        
        do {
            try session.updateApplicationContext(message)
            print("📦 [Watch] Sent via Application Context")
        } catch {
            print("❌ [Watch] Error sending via Application Context: \(error.localizedDescription)")
            // Fallback to UserInfo transfer (guaranteed delivery)
            sendViaUserInfo(message)
        }
    }
    
    /// Sends message via UserInfo transfer (guaranteed background delivery)
    private func sendViaUserInfo(_ message: [String: Any]) {
        session.transferUserInfo(message)
        print("📨 [Watch] Sent via UserInfo transfer (guaranteed delivery)")
    }
    
    // MARK: - Receiving Messages from Phone
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            print("📨 [Watch] Received message from phone: \(message)")
            self.handleReceivedData(message)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            print("📨 [Watch] Received message from phone (with reply): \(message)")
            self.handleReceivedData(message)
        }
        let reply = ["received": true]
        print("📤 [Watch] Sending reply to phone: \(reply)")
        replyHandler(reply)
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            print("📦 [Watch] Received application context from phone: \(applicationContext)")
            self.handleReceivedData(applicationContext)
        }
    }
    
    // MARK: - Receiving UserInfo from Phone (Background Transfer)
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            print("📨 [Watch] Received userInfo from phone: \(userInfo)")
            self.handleReceivedData(userInfo)
        }
    }
    
    // MARK: - Handle Received Data
    
    private func handleReceivedData(_ data: [String: Any]) {
        // Check if this is workout data
        if let messageType = data["messageType"] as? String,
           messageType == WorkoutDataTransferWatch.MessageType.workoutData.rawValue,
           let workoutData = data[WorkoutDataTransferWatch.workoutDataKey] as? [String: Any],
           let workout = WorkoutDataTransferWatch.decodeWorkout(workoutData) {
            print("✅ [Watch] Received workout data from phone")
            saveWorkoutToDatabase(workout)
        } else if let workoutData = data[WorkoutDataTransferWatch.workoutDataKey] as? [String: Any],
                  let workout = WorkoutDataTransferWatch.decodeWorkout(workoutData) {
            // Fallback: check for workoutData key directly
            print("✅ [Watch] Received workout data (without messageType)")
            saveWorkoutToDatabase(workout)
        } else if data["workoutCompleted"] as? Bool == true {
            // Legacy support for boolean flag (shouldn't happen with new code)
            print("⚠️ [Watch] Received legacy workoutCompleted flag (no data)")
        }
    }
    
    // MARK: - Save Workout to Database
    
    private func saveWorkoutToDatabase(_ workout: Workout) {
        // Post notification with workout data for the app to handle
        NotificationCenter.default.post(
            name: NSNotification.Name("WorkoutDataReceived"),
            object: nil,
            userInfo: ["workout": workout]
        )
        print("📢 [Watch] Posted WorkoutDataReceived notification with workout: \(workout.id)")
    }
}
