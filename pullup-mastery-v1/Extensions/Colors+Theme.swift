//
//  Colors+Theme.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI

extension Color {
    // Primary brand colors
    static let pullupBlue = Color(red: 0.2, green: 0.4, blue: 0.8)
    static let pullupGreen = Color(red: 0.2, green: 0.7, blue: 0.3)
    static let pullupOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let pullupRed = Color(red: 0.9, green: 0.3, blue: 0.3)
    
    // Workout type colors
    static let maxDayColor = pullupRed
    static let subMaxColor = pullupOrange  
    static let ladderColor = pullupGreen
    
    // UI colors
    static let cardBackground = Color(.systemBackground)
    static let secondaryCardBackground = Color(.secondarySystemBackground)
    static let accent = pullupBlue
}

// Haptic feedback helper
struct HapticManager {
    static let shared = HapticManager()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    func light() {
        lightImpact.impactOccurred()
    }
    
    func medium() {
        mediumImpact.impactOccurred()
    }
    
    func heavy() {
        heavyImpact.impactOccurred()
    }
    
    func selection() {
        selectionFeedback.selectionChanged()
    }
    
    func success() {
        notificationFeedback.notificationOccurred(.success)
    }
    
    func warning() {
        notificationFeedback.notificationOccurred(.warning)
    }
    
    func error() {
        notificationFeedback.notificationOccurred(.error)
    }
}
