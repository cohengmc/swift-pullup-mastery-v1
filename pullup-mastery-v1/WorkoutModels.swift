//
//  WorkoutModels.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var date: Date
    var type: WorkoutType
    var sets: [WorkoutSet]
    var completed: Bool
    var notes: String?
    
    init(type: WorkoutType, date: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.type = type
        self.sets = []
        self.completed = false
        self.notes = nil
    }
    
    var totalReps: Int {
        sets.reduce(0) { $0 + $1.reps }
    }
    
    var completedSets: Int {
        sets.filter { $0.reps > 0 }.count
    }
}

@Model
final class WorkoutSet {
    var id: UUID
    var setNumber: Int
    var reps: Int
    var restTime: Int // in seconds
    var completed: Bool
    var workout: Workout?
    
    init(setNumber: Int, reps: Int = 0, restTime: Int = 0) {
        self.id = UUID()
        self.setNumber = setNumber
        self.reps = reps
        self.restTime = restTime
        self.completed = false
    }
}

enum WorkoutType: String, CaseIterable, Codable {
    case maxDay = "Max Day"
    case subMaxVolume = "Sub Max Volume"
    case ladderVolume = "Ladder Volume"
    
    var description: String {
        switch self {
        case .maxDay:
            return "3 max effort sets, 5+ minute rest"
        case .subMaxVolume:
            return "10 sets at 50% max, 1 minute rest"
        case .ladderVolume:
            return "5 ascending ladders, 30 second rest"
        }
    }
    
    var maxSets: Int {
        switch self {
        case .maxDay: return 3
        case .subMaxVolume: return 10
        case .ladderVolume: return 5
        }
    }
    
    var restTime: Int {
        switch self {
        case .maxDay: return 300 // 5 minutes
        case .subMaxVolume: return 60 // 1 minute
        case .ladderVolume: return 30 // 30 seconds
        }
    }
}
