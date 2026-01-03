//
//  WorkoutDataTransferWatch.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/22/25.
//

import Foundation

/// Utility class for encoding and decoding Workout objects to/from dictionaries
/// for transmission via WatchConnectivity (watchOS version)
class WorkoutDataTransferWatch {
    
    // MARK: - Encoding
    
    /// Encodes a Workout object to a dictionary for WatchConnectivity transmission
    static func encodeWorkout(_ workout: Workout) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Encode UUID as string
        dict["id"] = workout.id.uuidString
        
        // Encode date as ISO8601 string
        let formatter = ISO8601DateFormatter()
        dict["date"] = formatter.string(from: workout.date)
        
        // Encode workout type as raw value string
        dict["type"] = workout.type.rawValue
        
        // Encode sets array
        dict["sets"] = workout.sets
        
        print("📤 [Transfer] Encoded workout: ID=\(workout.id), Type=\(workout.type.rawValue), Sets=\(workout.sets.count)")
        
        return dict
    }
    
    // MARK: - Decoding
    
    /// Decodes a dictionary to a Workout object
    static func decodeWorkout(_ data: [String: Any]) -> Workout? {
        guard let idString = data["id"] as? String,
              let uuid = UUID(uuidString: idString),
              let dateString = data["date"] as? String,
              let typeString = data["type"] as? String,
              let workoutType = WorkoutType(rawValue: typeString),
              let sets = data["sets"] as? [Int] else {
            print("❌ [Transfer] Failed to decode workout data: \(data)")
            return nil
        }
        
        // Parse date from ISO8601 string
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            print("❌ [Transfer] Failed to parse date from: \(dateString)")
            return nil
        }
        
        // Create workout object
        let workout = Workout(type: workoutType, date: date)
        workout.id = uuid
        workout.sets = sets
        
        print("📥 [Transfer] Decoded workout: ID=\(workout.id), Type=\(workout.type.rawValue), Sets=\(workout.sets.count)")
        
        return workout
    }
    
    // MARK: - Message Type Keys
    
    static let messageTypeKey = "messageType"
    static let workoutDataKey = "workoutData"
    
    enum MessageType: String {
        case workoutCompleted = "workoutCompleted"
        case workoutData = "workoutData"
    }
}

