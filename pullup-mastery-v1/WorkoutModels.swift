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
    var sets: [Int]
    
    init(type: WorkoutType, date: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.type = type
        self.sets = []
    }
    
    var totalReps: Int {
            switch type {
            case .ladderVolume:
                // For ladders, each 'n' in sets represents the sum of 1...n.
                // This is calculated using the formula: n * (n + 1) / 2
                return sets.reduce(0) { total, n in
                    total + (n * (n + 1)) / 2
                }
            default:
                // For all other workout types, just sum the reps in the sets.
                return sets.reduce(0, +)
            }
        }
    
    var completedSets: Int {
        return sets.count
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
